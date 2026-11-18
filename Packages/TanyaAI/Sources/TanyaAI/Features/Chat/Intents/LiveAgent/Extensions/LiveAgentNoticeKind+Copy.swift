//
//  LiveAgentNoticeKind+Copy.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

extension LiveAgentNoticeKind {
    /// Chip abu (Figma `time_stamp`) untuk awal dan akhir sesi yang sudah dilayani agen. Nil = tanpa chip.
    var chip: ChatCopy? {
        switch self {
        case .joined: return .agentStartedChip
        case .ended, .idleTimeout: return .agentEndedChip
        case .connecting, .canceled, .queueTimeout, .unavailable, .notContinued: return nil
        }
    }

    /// Kartu di bawah chip. Sesi yang dimulai cukup chip; sesi yang ditutup agen atau berakhir tanpa aktivitas memakai
    /// kartu yang sama. Waktu antre habis dan sambungan ke sistem agen hilang sama-sama berarti agen tidak didapat.
    var card: (title: ChatCopy, message: ChatCopy)? {
        switch self {
        case .joined: return nil
        case .connecting: return (.agentConnectingTitle, .agentConnectingMessage)
        case .ended, .idleTimeout: return (.agentEndedTitle, .agentEndedMessage)
        case .canceled: return (.agentCanceledTitle, .agentCanceledMessage)
        case .queueTimeout, .unavailable: return (.agentUnavailableTitle, .agentUnavailableMessage)
        case .notContinued: return (.agentNotContinuedTitle, .agentNotContinuedMessage)
        }
    }
}
