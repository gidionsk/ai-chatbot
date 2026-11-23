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
        case .referenceLetterChoices, .referenceLetterPIN:
            // Sheet surat referensi mengikuti percakapan chat, bukan sesi live agent.
            return true
        }
    }

    static func rejectedAttachment(
        from session: AgentSessionKey?,
        pickerSession: AgentSessionKey?,
        activeSheet: ChatSheet?
    ) -> ChatSheet? {
        guard let session, session == pickerSession, activeSheet == nil else { return nil }
        return .attachment(session, isFormatRejected: true)
    }

    func afterConversationChange() -> ChatSheet? {
        referenceLetterMessageID == nil ? self : nil
    }

    /// Respons success-id dari stream maupun history mengakhiri pilihan dan PIN untuk pesan pemiliknya.
    func afterReferenceLetterCompletion(in messages: [ChatMessage]) -> ChatSheet? {
        guard let id = referenceLetterMessageID else { return self }
        return messages.contains { $0.id == id && $0.successID != nil } ? nil : self
    }
}
