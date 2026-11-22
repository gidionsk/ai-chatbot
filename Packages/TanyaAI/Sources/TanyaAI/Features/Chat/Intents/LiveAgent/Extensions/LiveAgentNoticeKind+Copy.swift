//
//  LiveAgentNoticeKind+Copy.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

extension LiveAgentNoticeKind {
    /// Kartu status di antara pesan; nil = tidak tampil. Agen bergabung tidak punya kartu sendiri karena kartu pembuka
    /// sesi berganti menjadi `connected`. Sesi yang ditutup agen atau berakhir tanpa aktivitas memakai kartu yang sama.
    /// Waktu antre habis dan sambungan ke sistem agen hilang sama-sama berarti agen tidak didapat.
    var card: (title: ChatCopy, message: ChatCopy)? {
        switch self {
        case .joined: return nil
        case .connecting: return (.agentConnectingTitle, .agentConnectingMessage)
        case .connected: return (.agentConnectedTitle, .agentConnectedMessage)
        case .ended, .idleTimeout: return (.agentEndedTitle, .agentEndedMessage)
        case .canceled: return (.agentCanceledTitle, .agentCanceledMessage)
        case .queueTimeout, .unavailable: return (.agentUnavailableTitle, .agentUnavailableMessage)
        case .notContinued: return (.agentNotContinuedTitle, .agentNotContinuedMessage)
        }
    }
}
