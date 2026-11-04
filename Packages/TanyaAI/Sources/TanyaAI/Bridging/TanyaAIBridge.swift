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
    /// True setelah history pertama selesai; sebelum itu halaman menampilkan loading, bukan sambutan.
    @Published
    private(set) var isHistoryLoaded = false
    @Published
    var connection = ChatConnection.connecting
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

    /// 401 = sesi habis; 404/410 = percakapan hilang, sama dengan gagal permanen saat menyambung.
    /// Gagal kirim lain cukup menjadi bubble gagal. TODO: Gagal stop lain (tanpa koneksi, 429) belum punya
    /// tampilan; sementara stop bisa ditekan lagi.
    func didFailRequest(_ error: Error) {
        guard case let .response(statusCode, _)? = error as? TanyaAITransportError else { return }
        if ChatBackoff.isUnauthorized(statusCode: statusCode) {
            expireSession()
        } else if ChatBackoff.isConversationGone(statusCode: statusCode) {
            failConnection(error)
        }
    }

    /// Gagal permanen dari jalur mana pun: tutup stream yang terbuka, berhenti menyambung, dan beri tahu host
    /// sekali walau stream juga gagal dengan error yang sama.
    func failConnection(_ error: Error) {
        guard connection != .closed, connection != .expired else { return }
        connection = .closed
        connectionTask?.cancel()
        onConnectionFailed?(error)
    }

    /// Sesi OMNI habis (401) dari jalur mana pun: tutup stream yang terbuka, berhenti menyambung, dan beri tahu
    /// host sekali. Status ini final selama bridge hidup.
    func expireSession() {
        guard connection != .expired else { return }
        connection = .expired
        connectionTask?.cancel()
        onSessionExpired?()
    }

    /// Event `message` digabung ke daftar; `turn_end` milik pertanyaan yang ditunggu membuka kunci kirim.
    func apply(_ event: ChatEvent) {
        switch event {
        case .message(let message):
            messages = messages.merging([message])
            removeDeliveredQuestions()
        case .turnEnd(let seq):
            turn.end(seq: seq)
        case .ignored:
            break
        }
    }

    /// History yang sudah dikejar; percakapan berbeda dari sebelumnya mengganti daftar, bukan digabung.
    func replaceOrMerge(_ history: [ChatMessage], conversationID: String) {
        guard self.conversationID == nil || self.conversationID == conversationID else {
            messages = history.merging([])
            localQuestions = []
            turn.cancel()
            eventCursor = nil
            self.conversationID = conversationID
            isHistoryLoaded = true
            return
        }
        self.conversationID = conversationID
        messages = messages.merging(history)
        isHistoryLoaded = true
        // Pertanyaan yang terlewat stream saat putus datang lewat history.
        removeDeliveredQuestions()
    }
}
