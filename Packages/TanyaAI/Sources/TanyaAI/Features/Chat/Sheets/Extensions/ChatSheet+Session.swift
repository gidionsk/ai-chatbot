//
//  ChatSheet+Session.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

extension ChatSheet {
    /// Sheet masih milik sesi yang tampil: lampiran ke sesi yang dilayani agen, konfirmasi End Session ke sesi yang
    /// barnya tampil. Nil = lampiran tidak tersedia atau bar tidak tampil.
    func isCurrent(attachmentSession: AgentSessionKey?, leaveSession: AgentSessionKey?) -> Bool {
        switch self {
        case .attachment(let session, _):
            return session == attachmentSession
        case .leaveAgent(let session):
            return session == leaveSession
        }
    }
}
