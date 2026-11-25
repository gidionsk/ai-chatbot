//
//  ChatSheetSessionTests.swift
//  TanyaAITests
//
//  Created by Wendra on 20/11/26.
//

import Testing

@testable import TanyaAI

/// Sheet lampiran dan konfirmasi End Session hanya berlaku untuk sesi agen tempat keduanya dibuka.
struct ChatSheetSessionTests {
    private let sessionA = AgentSessionKey(conversationID: "a", queueStartSeq: 4)
    private let sessionB = AgentSessionKey(conversationID: "b", queueStartSeq: 4)

    @Test
    func anAttachmentSheetFollowsTheServingSession() {
        let sheet = ChatSheet.attachment(sessionA, isFormatRejected: false)
        #expect(sheet.isCurrent(attachmentSession: sessionA, leaveSession: sessionA))
        #expect(!sheet.isCurrent(attachmentSession: sessionB, leaveSession: sessionB), "reconnect ke percakapan lain")
        #expect(!sheet.isCurrent(attachmentSession: nil, leaveSession: sessionA), "agen tidak melayani lagi")
    }

    @Test
    func aConfirmationFollowsTheSessionWithTheBar() {
        let sheet = ChatSheet.leaveAgent(sessionA)
        #expect(sheet.isCurrent(attachmentSession: nil, leaveSession: sessionA), "masih antre setelah sapaan")
        #expect(!sheet.isCurrent(attachmentSession: sessionB, leaveSession: sessionB))
        #expect(!sheet.isCurrent(attachmentSession: nil, leaveSession: nil), "bar hilang")
    }

    @Test
    func rejectedAttachmentPreservesAnOpenSheet() {
        let pin = ChatSheet.referenceLetterPIN(messageID: "letter")
        #expect(ChatSheet.rejectedAttachment(from: sessionA, pickerSession: sessionA, activeSheet: pin) == nil)
        #expect(ChatSheet.rejectedAttachment(from: sessionA, pickerSession: sessionB, activeSheet: nil) == nil)
        let retry = ChatSheet.rejectedAttachment(from: sessionA, pickerSession: sessionA, activeSheet: nil)
        #expect(retry == .attachment(sessionA, isFormatRejected: true))
    }

    @Test
    func conversationChangeClosesReferenceLetterSheets() {
        #expect(ChatSheet.referenceLetterPIN(messageID: "letter").afterConversationChange() == nil)
        let choices = ChatSheet.referenceLetterChoices(messageID: "letter", field: .format)
        #expect(choices.afterConversationChange() == nil)
        let leave = ChatSheet.leaveAgent(sessionA)
        #expect(leave.afterConversationChange() == leave)
    }
}
