//
//  TanyaAIBridge+State.swift
//  TanyaAI
//
//  Created by Wendra on 22/11/26.
//

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
