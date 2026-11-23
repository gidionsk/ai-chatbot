//
//  AgentSessionMark.swift
//  TanyaAI
//
//  Created by Wendra on 23/11/26.
//

/// Batas sesi agen dari stream selain pesan: `agent_joined` membuka sesi, `agent_connecting` memulai antrean baru,
/// dan event `state` keluar dari antre atau agen menutup sesi. `isServed` = keluar dari `AGENT_ACTIVE`, jadi ada sesi
/// dengan agen walau pesan agen dan `agent_joined`-nya tidak diterima (mis. dibuka lagi saat sesi berjalan).
enum AgentSessionMark: Hashable, Comparable {
    case joined(seq: Int)
    case queued(seq: Int)
    case exit(seq: Int, isServed: Bool)

    var seq: Int {
        switch self {
        case .joined(let seq), .queued(let seq), .exit(let seq, _):
            return seq
        }
    }

    /// Urut `seq`. Event stream ber-`seq` unik; `seq` sama hanya dari posisi tunggu `leave-agent` (lihat
    /// `AgentSessionExits`), yang diambil setelah event terakhir, jadi penanda keluar dibaca paling akhir.
    static func < (lhs: AgentSessionMark, rhs: AgentSessionMark) -> Bool {
        guard lhs.seq == rhs.seq else { return lhs.seq < rhs.seq }
        return !lhs.isExit && rhs.isExit
    }
}

private extension AgentSessionMark {
    var isExit: Bool {
        guard case .exit = self else { return false }
        return true
    }
}
