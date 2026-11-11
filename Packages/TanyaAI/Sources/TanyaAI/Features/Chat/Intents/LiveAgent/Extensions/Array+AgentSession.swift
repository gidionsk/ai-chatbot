//
//  Array+AgentSession.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

extension Array where Element == ChatMessage {
    /// Kartu selesai untuk sesi agen di history, karena history tidak membawa event `system`. Sesi berakhir saat bot
    /// menjawab lagi, atau di akhir daftar bila agen tidak sedang melayani; kartunya tepat setelah pesan agen
    /// terakhir sesi itu. Sesi yang sudah punya kartu dari stream di antara keduanya tidak diberi kartu lagi.
    func endedAgentSessions(isOngoing: Bool, closedBy notices: [LiveAgentNotice]) -> [LiveAgentNotice] {
        var sessions: [(lastAgentSeq: Int, nextSeq: Int)] = []
        var lastAgentSeq: Int?
        for message in self {
            if message.author == .agent {
                lastAgentSeq = message.seq
            } else if message.author == .assistant, let agentSeq = lastAgentSeq {
                sessions.append((agentSeq, message.seq))
                lastAgentSeq = nil
            }
        }
        if let agentSeq = lastAgentSeq, !isOngoing {
            sessions.append((agentSeq, .max))
        }
        return
            sessions
            .filter { session in !notices.contains { $0.seq > session.lastAgentSeq && $0.seq < session.nextSeq } }
            .map { LiveAgentNotice(kind: .ended, seq: $0.lastAgentSeq) }
    }
}
