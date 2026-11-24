//
//  Array+AgentSession.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

extension Array where Element == ChatMessage {
    /// Kartu "Connected" untuk tiap sesi agen dari pesan dan event stream (`notices`, urut `seq`), karena history tidak
    /// membawa event. Lihat `AgentSessionScan`. Kartu memakai `seq` event antre sesi itu bila ada, jadi tidak berpindah
    /// saat kartu antre berganti; selain itu `seq` pesan tepat sebelum pesan agen pertama (`Int.min` bila tidak ada),
    /// atau `seq` `agent_joined`. Pesan itu bot atau nasabah, jadi tidak pernah menjadi kartu selesai atau "tidak
    /// dilanjutkan". Event ber-`seq` sama dengan pesan dibaca setelah pesannya.
    func connectedAgentSessions(streamNotices notices: [LiveAgentNotice]) -> [LiveAgentNotice] {
        var scan = AgentSessionScan()
        var pending = notices[...]
        for message in self {
            while let notice = pending.first, notice.seq < message.seq {
                scan.read(notice)
                pending = pending.dropFirst()
            }
            scan.read(message)
        }
        pending.forEach { scan.read($0) }
        return scan.cards
    }

    /// Kartu selesai untuk sesi agen tanpa kartu penutup dari stream, karena history tidak membawa event `system`.
    /// Batas sesi dari stream (`marks`: `agent_joined`, `agent_connecting`, dan event `state` keluar dari antre atau
    /// agen, lihat `AgentSessionExits`) dibaca bersama pesan menurut `seq`; lihat `AgentSessionEndScan`. Pesan nasabah
    /// selama sesi tetap di atas kartu. Penanda ber-`seq` sama dengan pesan dibaca setelah pesannya.
    func endedAgentSessions(
        isOngoing: Bool,
        closedBy notices: [LiveAgentNotice],
        marks: [AgentSessionMark]
    ) -> [LiveAgentNotice] {
        var scan = AgentSessionEndScan(closingNotices: notices)
        var pending = marks.sorted()[...]
        for message in self {
            while let mark = pending.first, mark.seq < message.seq {
                scan.read(mark)
                pending = pending.dropFirst()
            }
            scan.read(message)
        }
        pending.forEach { scan.read($0) }
        return scan.finish(isOngoing: isOngoing)
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
