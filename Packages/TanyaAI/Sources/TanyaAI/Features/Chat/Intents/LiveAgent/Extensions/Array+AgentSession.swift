//
//  Array+AgentSession.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

extension Array where Element == ChatMessage {
    /// Kartu "Connected" untuk tiap sesi agen, karena history tidak membawa event. Sesi dimulai di pesan agen pertama
    /// setelah bot menjawab (atau di awal daftar); pesan itu bisa sapaan otomatis selama antre. Kartu memakai `seq`
    /// event antre sesi itu bila ada dari stream, jadi tidak berpindah saat kartu antre berganti; selain itu `seq`
    /// pesan tepat sebelum pesan agen pertama (`Int.min` bila tidak ada), sehingga tampil tepat setelahnya. Pesan itu
    /// bot atau nasabah, jadi tidak pernah menjadi kartu selesai atau "tidak dilanjutkan".
    func connectedAgentSessions(openedBy openers: [LiveAgentNotice]) -> [LiveAgentNotice] {
        var cards: [LiveAgentNotice] = []
        var boundarySeq = Int.min
        var previousSeq = Int.min
        var isInSession = false
        for message in self {
            switch message.author {
            case .agent:
                if !isInSession {
                    let opener = openers.last { $0.seq > boundarySeq && $0.seq < message.seq }
                    cards.append(LiveAgentNotice(kind: .connected, seq: opener?.seq ?? previousSeq))
                }
                isInSession = true
            case .assistant:
                boundarySeq = message.seq
                isInSession = false
            case .user, .unknown:
                break
            }
            previousSeq = message.seq
        }
        return cards
    }

    /// Kartu selesai untuk sesi agen di history, karena history tidak membawa event `system`. Sesi berakhir saat bot
    /// menjawab lagi, atau di akhir daftar bila tidak sedang antre atau dilayani agen; kartunya tepat setelah pesan
    /// agen terakhir sesi itu. Sesi yang sudah punya kartu dari stream di antara keduanya tidak diberi kartu lagi.
    func endedAgentSessions(isOngoing: Bool, closedBy notices: [LiveAgentNotice]) -> [LiveAgentNotice] {
        var sessions: [(lastAgentSeq: Int, nextSeq: Int)] = []
        var lastAgentSeq: Int?
        for message in self {
            switch message.author {
            case .agent:
                lastAgentSeq = message.seq
            case .assistant:
                guard let agentSeq = lastAgentSeq else { continue }
                sessions.append((agentSeq, message.seq))
                lastAgentSeq = nil
            case .user, .unknown:
                break
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

    /// Permintaan agen yang tidak dilanjutkan: pesan bot ber-intent `liveAgent` yang tidak diikuti pesan agen sampai
    /// bot menjawab lagi, atau sampai akhir daftar bila `isSettled` (tidak antre/dilayani dan turn serah terima sudah
    /// selesai). Kartunya tepat setelah pesan serah terima. Rentang yang sudah punya kartu penutup dari stream tidak
    /// diberi kartu lagi; `notices` tidak boleh berisi kartu antre, karena kartu itu tersembunyi setelah antre selesai.
    func unfinishedHandovers(isSettled: Bool, closedBy notices: [LiveAgentNotice]) -> [LiveAgentNotice] {
        var handovers: [(seq: Int, nextSeq: Int)] = []
        var handoverSeq: Int?
        for message in self {
            switch message.author {
            case .agent:
                handoverSeq = nil
            case .assistant:
                if let seq = handoverSeq {
                    handovers.append((seq, message.seq))
                }
                handoverSeq = message.intent == .liveAgent ? message.seq : nil
            case .user, .unknown:
                break
            }
        }
        if let seq = handoverSeq, isSettled {
            handovers.append((seq, .max))
        }
        return
            handovers
            .filter { handover in !notices.contains { $0.seq > handover.seq && $0.seq < handover.nextSeq } }
            .map { LiveAgentNotice(kind: .notContinued, seq: $0.seq) }
    }
}
