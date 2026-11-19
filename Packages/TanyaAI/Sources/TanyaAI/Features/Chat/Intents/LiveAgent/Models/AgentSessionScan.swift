//
//  AgentSessionScan.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

/// Pemindai pesan dan event stream urut `seq` untuk kartu "Connected" tiap sesi agen. Sesi dimulai di pesan agen
/// pertama (bisa sapaan otomatis selama antre) atau `agent_joined`, mana yang lebih dulu, dan berakhir saat bot
/// menjawab, event penutup datang (selesai, antre habis, batal, agen tidak tersedia), atau antrean baru dimulai (event
/// penutup lama bisa terlewat bila replay terpangkas). Event antre hanya menjadi posisi kartu bila belum ditutup
/// sebelum sesinya dimulai.
struct AgentSessionScan {
    private(set) var cards: [LiveAgentNotice] = []
    private var openerSeq: Int?
    private var previousMessageSeq = Int.min
    private var isInSession = false

    /// Kartu sesi yang dimulai pesan agen tampil tepat setelah pesan sebelumnya, bila tidak ada event antre.
    mutating func read(_ message: ChatMessage) {
        switch message.author {
        case .agent:
            start(fallbackSeq: previousMessageSeq)
        case .assistant:
            close()
        case .user, .unknown:
            break
        }
        previousMessageSeq = message.seq
    }

    /// Kartu sesi yang dimulai `agent_joined` tampil di posisi event itu, bila tidak ada event antre.
    mutating func read(_ notice: LiveAgentNotice) {
        switch notice.kind {
        case .connecting:
            close()
            openerSeq = notice.seq
        case .joined:
            start(fallbackSeq: notice.seq)
        case .ended, .idleTimeout, .canceled, .queueTimeout, .unavailable:
            close()
        case .connected, .notContinued:
            break
        }
    }
}

// MARK: - Helpers

private extension AgentSessionScan {
    mutating func start(fallbackSeq: Int) {
        guard !isInSession else { return }
        isInSession = true
        cards.append(LiveAgentNotice(kind: .connected, seq: openerSeq ?? fallbackSeq))
    }

    mutating func close() {
        isInSession = false
        openerSeq = nil
    }
}
