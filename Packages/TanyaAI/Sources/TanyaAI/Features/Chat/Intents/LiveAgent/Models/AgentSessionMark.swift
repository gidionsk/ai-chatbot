//
//  AgentSessionMark.swift
//  TanyaAI
//
//  Created by Wendra on 23/11/26.
//

/// Batas sesi agen dari stream selain pesan: `agent_joined` membuka sesi, event `state` keluar dari agen menutupnya.
enum AgentSessionMark: Comparable {
    case joined(seq: Int)
    case exit(seq: Int)

    var seq: Int {
        switch self {
        case .joined(let seq), .exit(let seq):
            return seq
        }
    }

    /// Urut `seq`; pada `seq` sama sesi dibuka sebelum ditutup.
    static func < (lhs: AgentSessionMark, rhs: AgentSessionMark) -> Bool {
        guard lhs.seq == rhs.seq else { return lhs.seq < rhs.seq }
        return lhs.isJoined && !rhs.isJoined
    }
}

private extension AgentSessionMark {
    var isJoined: Bool {
        guard case .joined = self else { return false }
        return true
    }
}
