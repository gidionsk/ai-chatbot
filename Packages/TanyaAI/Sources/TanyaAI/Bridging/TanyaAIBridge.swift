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
    /// Urut `seq` naik; pesan nasabah juga baru muncul setelah datang lewat stream, bukan saat dikirim.
    @Published
    private(set) var messages: [ChatMessage] = []
    /// Pertanyaan yang sedang ditunggu jawabannya (lihat `ChatTurn`).
    @Published
    private(set) var turn = ChatTurn()
    /// True setelah history pertama selesai; sebelum itu halaman menampilkan loading, bukan sambutan.
    @Published
    private(set) var isHistoryLoaded = false
    @Published
    var connection = ChatConnection.connecting
    /// Percakapan dari `/chat/init` terakhir; nil sebelum init pertama berhasil.
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

    /// Titik bergerak sampai pertanyaan tampil, lalu stop sampai `turn_end`.
    var turnPhase: ChatTurnPhase { turn.phase }

    /// Replay stream dimulai setelah pesan atau event terakhir yang sudah diterima.
    var lastEventID: String? {
        [messages.latestSeq, eventCursor].compactMap { $0 }.max().map(String.init)
    }

    /// Loading hanya selama pembukaan pertama masih berjalan; gagal permanen atau sesi habis menghentikannya.
    var isLoadingHistory: Bool { !isHistoryLoaded && connection == .connecting }

    /// Sambutan hanya untuk percakapan kosong; pesan pertama (dari stream) langsung menggantikannya.
    var isWelcomeVisible: Bool { isHistoryLoaded && messages.isEmpty }

    /// Bisa mengirim setelah init berhasil, juga selama menyambung ulang; tidak setelah ditutup atau sesi habis.
    var isReady: Bool {
        conversationID != nil && connection != .closed && connection != .expired
    }

    /// Satu pertanyaan per waktu: selama menunggu jawaban, chat baru ditolak tanpa diteruskan ke host.
    /// True bila gateway menerima pesan (ack 202); false mempertahankan draft di composer.
    func send(_ text: String) async -> Bool {
        guard !isAwaitingReply, isReady, let conversationID else { return false }
        // Penanda pertanyaan ini: respons yang datang setelah turn berganti tidak mengubah turn yang baru.
        let clientMessageID = UUID().uuidString
        turn.start(clientMessageID: clientMessageID)
        do {
            let data = try await transport.sendMessage(
                conversationID: conversationID, clientMessageID: clientMessageID, text: text
            )
            let ack = try? JSONDecoder.wire.decode(WireEnvelope<WireSendAck>.self, from: data).data
            turn.accept(questionSeq: ack.flatMap { Int($0.seq) }, for: clientMessageID)
            // Pertanyaan bisa datang lebih dulu tanpa `client_msg_id`; seq dari ack baru bisa mencocokkannya.
            revealQuestion()
            return true
        } catch {
            turn.cancel(clientMessageID: clientMessageID)
            didFailRequest(error)
            return false
        }
    }

    /// Stop: hanya setelah pertanyaan tampil. `canceled:true` menunggu `turn_end` di stream (tombstone pertanyaan
    /// ikut datang); `canceled:false` = gateway tidak punya turn aktif, jadi kunci dibuka di sini karena
    /// `turn_end` tidak akan datang. Gagal = stop bisa ditekan lagi (cancel idempoten).
    func cancelTurn() async {
        guard let conversationID, let clientMessageID = turn.startCanceling() else { return }
        do {
            let data = try await transport.cancelTurn(conversationID: conversationID)
            let result = try JSONDecoder.wire.decode(WireEnvelope<WireCancel>.self, from: data).data
            if !result.isCanceled {
                turn.cancel(clientMessageID: clientMessageID)
            }
        } catch {
            turn.stopCanceling(clientMessageID: clientMessageID)
            didFailRequest(error)
        }
    }

    /// 401 = sesi habis; 404/410 = percakapan hilang, sama dengan gagal permanen saat menyambung.
    /// TODO: Gagal kirim/stop lain (tanpa koneksi, 409 `turn_locked`, 429, 400) ditampilkan sebagai snackbar
    /// di atas composer pada PR tampilan; sementara draft tetap dan tombol bisa ditekan lagi.
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
            revealQuestion()
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
        revealQuestion()
    }

    /// Pertanyaan yang ditunggu sudah ada di daftar: titik bergerak berganti stop. Turn hanya diubah bila
    /// statusnya benar-benar berubah, supaya pesan lain tidak memicu render ulang composer.
    func revealQuestion() {
        guard turn.isQuestionArriving(in: messages) else { return }
        turn.showQuestion()
    }
}
