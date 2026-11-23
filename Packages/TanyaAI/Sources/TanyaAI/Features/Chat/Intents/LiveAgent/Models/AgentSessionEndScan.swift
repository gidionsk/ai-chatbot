//
//  AgentSessionEndScan.swift
//  TanyaAI
//
//  Created by Wendra on 23/11/26.
//

/// Pembaca berurutan untuk kartu selesai sesi agen (lihat `endedAgentSessions`). Sesi dibuka pesan agen atau
/// `agent_joined`, lalu ditutup event `state` keluar dari agen, jawaban bot berikutnya, atau akhir daftar. Kartunya di
/// posisi event keluar bila ada; tanpa event itu (history) tepat setelah pesan agen terakhir. Sesi yang punya kartu
/// penutup dari stream (mis. `queue_canceled`, `agent_ended`) tidak diberi kartu lagi.
struct AgentSessionEndScan {
    let closingNotices: [LiveAgentNotice]
    private(set) var cards: [LiveAgentNotice] = []
    /// `seq` pesan agen atau `agent_joined` terakhir sesi yang sedang dibaca; nil = tidak ada sesi.
    private var lastSessionSeq: Int?
    private var exitSeq: Int?

    init(closingNotices: [LiveAgentNotice]) {
        self.closingNotices = closingNotices
    }

    mutating func read(_ message: ChatMessage) {
        switch message.author {
        case .agent:
            open(at: message.seq)
        case .assistant:
            close(before: message.seq)
        case .user, .unknown:
            break
        }
    }

    mutating func read(_ mark: AgentSessionMark) {
        switch mark {
        case .joined(let seq):
            open(at: seq)
        case .exit(let seq):
            guard lastSessionSeq != nil, exitSeq == nil else { return }
            exitSeq = seq
        }
    }

    /// Sesi terakhir ditutup bila sudah keluar dari agen, atau bila tidak sedang antre atau dilayani agen.
    mutating func finish(isOngoing: Bool) -> [LiveAgentNotice] {
        guard exitSeq != nil || !isOngoing else { return cards }
        close(before: .max)
        return cards
    }
}

private extension AgentSessionEndScan {
    /// Pesan agen atau `agent_joined` setelah event keluar memulai sesi baru tanpa harus menunggu jawaban bot.
    mutating func open(at seq: Int) {
        if exitSeq != nil {
            close(before: seq)
        }
        lastSessionSeq = seq
    }

    mutating func close(before boundary: Int) {
        guard let lastSeq = lastSessionSeq else { return }
        let position = exitSeq ?? lastSeq
        lastSessionSeq = nil
        exitSeq = nil
        guard !closingNotices.contains(where: { $0.seq > lastSeq && $0.seq < boundary }) else { return }
        cards.append(LiveAgentNotice(kind: .ended, seq: position))
    }
}
