//
//  TanyaAIBridge.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Combine
import Foundation

/// Jembatan host ↔ TanyaAI yang hidup selama halaman terbuka. Host membuatnya sekali (misalnya di view model
/// milik `@StateObject` destination) bersama `TanyaAIChatTransport`, lalu memberikannya ke `TanyaAIHost`.
/// TanyaAI yang menyambung (init → history → SSE), menyambung ulang, dan menggabungkan pesan.
@MainActor
public final class TanyaAIBridge: ObservableObject {
    /// Pesan dari gateway, urut `seq` naik.
    @Published
    private(set) var messages: [ChatMessage] = []
    /// Pertanyaan yang sudah tampil tetapi belum datang dari stream, termasuk yang gagal dikirim (urut waktu kirim).
    @Published
    var localQuestions: [LocalQuestion] = []
    /// Pertanyaan yang sedang ditunggu jawabannya (lihat `ChatTurn`).
    @Published
    var turn = ChatTurn()
    /// Pertanyaan terbaru yang dikirim dari halaman ini. Hanya berubah saat kirim, jadi salinan dari stream atau
    /// bubble gagal yang tersisa tidak dianggap kiriman baru.
    @Published var latestSentQuestionID: String?
    /// Pesan terlihat terbaru yang datang di luar turn nasabah, termasuk pertanyaan dari kanal lain. Jawaban turn
    /// sendiri tidak dihitung, karena pertanyaannya tetap parkir.
    @Published private(set) var latestIncomingMessageID: String?
    /// True setelah history pertama selesai; sebelum itu halaman menampilkan loading, bukan sambutan.
    @Published
    private(set) var isHistoryLoaded = false
    @Published
    var connection = ChatConnection.connecting
    /// State dari init terakhir, diperbarui event `state`. `unknown` sebelum init pertama. Lewat init maupun stream,
    /// status mengetik kedua pihak ikut dibersihkan (lihat `didChangeConversationState`).
    @Published var conversationState = ConversationState.unknown {
        didSet { didChangeConversationState() }
    }
    /// Kartu status live agent yang diterima selama halaman terbuka, urut `seq`.
    @Published private(set) var liveAgentNotices: [LiveAgentNotice] = []
    /// Permintaan keluar antrean sedang diproses; tombol batal tidak dikirim dua kali.
    @Published var isLeavingAgentQueue = false
    /// Indikator "agen sedang mengetik"; dimatikan oleh `typing:false`, pesan agen, atau batas `ttl_s`.
    @Published var isAgentTyping = false
    /// Penghapus indikator mengetik setelah batas waktunya; diganti setiap event `typing` baru.
    var agentTypingExpiry: Task<Void, Never>?
    /// Agen sedang diberi tahu nasabah mengetik (`typing:true` terakhir yang dikirim); tidak di-publish.
    var isUserTypingSent = false
    /// `typing:true` terkirim kurang dari `ChatWire.typingRefresh` yang lalu, jadi ketikan berikutnya tidak dikirim.
    var isUserTypingFresh = false
    var userTypingIdle: Task<Void, Never>?
    var userTypingRefresh: Task<Void, Never>?
    /// Sinyal terbaru yang belum dikirim (nil = tidak ada); sinyal yang menunggu digabung menjadi yang terbaru.
    var isUserTypingQueued: Bool?
    /// Nilai terakhir yang dikirim ke server; `false` tanpa `true` sebelumnya tidak perlu dikirim.
    var isUserTypingDelivered = false
    /// Satu-satunya pengirim `typing` yang berjalan; selesai saat tidak ada sinyal yang menunggu.
    var userTypingDelivery: Task<Void, Never>?
    /// Percakapan dari `/v1/chat/init` terakhir; nil sebelum init pertama berhasil.
    var conversationID: String?
    /// `id` event SSE terbesar yang sudah diterima (termasuk `turn_end`), bagian dari `Last-Event-ID`.
    var eventCursor: Int?
    /// Loop sambungan yang sedang berjalan; dibatalkan saat sesi habis agar stream yang terbuka ikut ditutup.
    var connectionTask: Task<Void, Never>?
    let transport: TanyaAIChatTransport
    let onSessionExpired: (() -> Void)?
    let onConnectionFailed: ((Error) -> Void)?
    let sleep: (TimeInterval) async throws -> Void

    /// `onSessionExpired` dipanggil sekali saat gateway menjawab 401 (sesi OMNI habis); stream tidak dibuka lagi.
    /// `onConnectionFailed` dipanggil sekali saat error yang tidak bisa di-retry (`retryable:false`) menghentikan
    /// sambungan; host menampilkan error sesuai polanya. Error berupa `TanyaAITransportError` dari transport.
    public convenience init(
        transport: TanyaAIChatTransport, onSessionExpired: (() -> Void)? = nil,
        onConnectionFailed: ((Error) -> Void)? = nil
    ) {
        self.init(
            transport: transport, onSessionExpired: onSessionExpired, onConnectionFailed: onConnectionFailed,
            sleep: ChatBackoff.sleep(seconds:)
        )
    }

    /// `sleep` disuntikkan test agar jeda reconnect instan.
    init(
        transport: TanyaAIChatTransport, onSessionExpired: (() -> Void)?,
        onConnectionFailed: ((Error) -> Void)? = nil, sleep: @escaping (TimeInterval) async throws -> Void
    ) {
        self.transport = transport
        self.onSessionExpired = onSessionExpired
        self.onConnectionFailed = onConnectionFailed
        self.sleep = sleep
    }
}

// MARK: - State

extension TanyaAIBridge {
    /// Sejak kirim sampai `turn_end` pertanyaan itu; kirim dan shortcut nonaktif.
    var isAwaitingReply: Bool { turn.isAwaiting }

    /// Stop sejak kirim sampai `turn_end`.
    var turnPhase: ChatTurnPhase { turn.phase }

    /// Daftar tampil: pesan gateway dengan pertanyaan lokal di posisi saat dikirim.
    var rows: [ChatRow] { messages.rows(with: localQuestions) }

    /// Replay stream dimulai setelah pesan atau event terakhir yang sudah diterima.
    var lastEventID: String? {
        [messages.latestSeq, eventCursor].compactMap { $0 }.max().map(String.init)
    }

    /// Loading hanya selama pembukaan pertama masih berjalan; gagal permanen atau sesi habis menghentikannya.
    var isLoadingHistory: Bool { !isHistoryLoaded && connection == .connecting }

    var historyPhase: ChatHistoryPhase {
        guard isHistoryLoaded else { return .loading }
        return messages.isEmpty ? .empty : .restored
    }

    /// Sambutan hanya untuk percakapan kosong; bubble pertanyaan pertama langsung menggantikannya.
    var isWelcomeVisible: Bool { isHistoryLoaded && messages.isEmpty && localQuestions.isEmpty }

    /// Saran hanya dari jawaban terakhir, dan hilang selama menunggu jawaban berikutnya.
    var followUps: [String] {
        guard !isAwaitingReply, let latest = messages.last, latest.author == .assistant else { return [] }
        return latest.followUps
    }

    /// Bisa mengirim setelah init berhasil, juga selama menyambung ulang; tidak setelah ditutup atau sesi habis.
    var isReady: Bool {
        conversationID != nil && connection != .closed && connection != .expired
    }
}

// MARK: - Actions

extension TanyaAIBridge {
    /// 401 = sesi habis; 404/410 = percakapan hilang, sama dengan gagal permanen saat menyambung.
    /// Gagal kirim lain cukup menjadi bubble gagal. TODO: Gagal stop lain (tanpa koneksi, 429) belum punya
    /// tampilan; sementara stop bisa ditekan lagi.
    /// `requestConversationID` = percakapan milik request; 404/410 dari percakapan yang sudah diganti init tidak
    /// menutup percakapan yang baru.
    func didFailRequest(_ error: Error, conversationID requestConversationID: String) {
        guard case let .response(statusCode, _)? = error as? TanyaAITransportError else { return }
        if ChatBackoff.isUnauthorized(statusCode: statusCode) {
            return expireSession()
        }
        guard ChatBackoff.isConversationGone(statusCode: statusCode), requestConversationID == conversationID
        else { return }
        failConnection(error)
    }

    /// Gagal permanen dari jalur mana pun: tutup stream yang terbuka, berhenti menyambung, dan beri tahu host
    /// sekali walau stream juga gagal dengan error yang sama.
    func failConnection(_ error: Error) {
        guard connection != .closed, connection != .expired else { return }
        connection = .closed
        connectionTask?.cancel()
        resetUserTyping()
        onConnectionFailed?(error)
    }

    /// Sesi OMNI habis (401) dari jalur mana pun: tutup stream yang terbuka, berhenti menyambung, dan beri tahu
    /// host sekali. Status ini final selama bridge hidup.
    func expireSession() {
        guard connection != .expired else { return }
        connection = .expired
        connectionTask?.cancel()
        resetUserTyping()
        onSessionExpired?()
    }

    /// Event `message` digabung ke daftar; `turn_end` milik pertanyaan yang ditunggu membuka kunci kirim.
    func apply(_ event: ChatEvent) {
        switch event {
        case .message(let message):
            messages = messages.merging([message])
            if message.author == .agent {
                showAgentTyping(false)
            }
            removeDeliveredQuestions()
            updateLatestIncomingMessage()
        case .turnEnd(let seq):
            turn.end(seq: seq)
        case .state(let state):
            conversationState = state
        case .notice(let notice):
            // Replay setelah reconnect bisa mengulang event yang sama; `seq` menjadi kuncinya.
            let others = liveAgentNotices.filter { $0.seq != notice.seq }
            liveAgentNotices = (others + [notice]).sorted { $0.seq < $1.seq }
        case .agentTyping(let isTyping, let lifetime):
            showAgentTyping(isTyping, lifetime: lifetime)
        case .ignored:
            break
        }
    }

    /// History yang sudah dikejar; percakapan berbeda dari sebelumnya mengganti daftar, bukan digabung.
    func replaceOrMerge(_ history: [ChatMessage], conversationID: String) {
        guard self.conversationID == nil || self.conversationID == conversationID else {
            messages = history.merging([])
            localQuestions = []
            liveAgentNotices = []
            showAgentTyping(false)
            resetUserTyping()
            turn.cancel()
            eventCursor = nil
            self.conversationID = conversationID
            isHistoryLoaded = true
            updateLatestIncomingMessage()
            return
        }
        self.conversationID = conversationID
        messages = messages.merging(history)
        isHistoryLoaded = true
        // Pertanyaan yang terlewat stream saat putus datang lewat history.
        removeDeliveredQuestions()
        updateLatestIncomingMessage()
    }

    private func updateLatestIncomingMessage() {
        guard !isAwaitingReply, let message = messages.last(where: { ChatRow.message($0).isVisible }) else { return }
        latestIncomingMessageID = message.id
    }
}
