//
//  LiveAgentNoticeKind+Copy.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

extension LiveAgentNoticeKind {
    /// Waktu antre habis dan sambungan ke sistem agen hilang sama-sama berarti agen tidak didapat.
    var title: ChatCopy {
        switch self {
        case .connecting: return .agentConnectingTitle
        case .ended: return .agentEndedTitle
        case .idleTimeout: return .agentIdleTitle
        case .canceled: return .agentCanceledTitle
        case .queueTimeout, .unavailable: return .agentUnavailableTitle
        }
    }

    var message: ChatCopy {
        switch self {
        case .connecting: return .agentConnectingMessage
        case .ended: return .agentEndedMessage
        case .idleTimeout: return .agentIdleMessage
        case .canceled: return .agentCanceledMessage
        case .queueTimeout, .unavailable: return .agentUnavailableMessage
        }
    }
}
