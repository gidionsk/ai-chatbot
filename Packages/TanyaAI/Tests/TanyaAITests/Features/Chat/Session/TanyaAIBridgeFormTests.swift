//
//  TanyaAIBridgeFormTests.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import Testing

@testable import TanyaAI

@MainActor
struct TanyaAIBridgeFormTests {
    @Test
    func replayKeepsTheSameFormAndLoadsInquiryOnce() async throws {
        let service = ReferenceLetterInquirySpy()
        let bridge = TanyaAIBridge(transport: FakeChatTransport(), services: .init(referenceLetter: service))
        let message = trigger()
        bridge.apply(.message(message))
        let session = try #require(bridge.referenceLetters[message.id])
        await waitUntil { session.phase == .editing }
        session.draft.destination = "Keep this draft"
        bridge.apply(.message(message))
        #expect(bridge.referenceLetters[message.id] === session)
        #expect(session.draft.destination == "Keep this draft")
        #expect(service.inquiryCount == 1)
        let rows: [ChatListItem] = [.message(.message(message), isSpaced: true)]
        #expect(
            rows.insertingReferenceLetters([message.id]).map(\.id) == [
                .message(message.id), .referenceLetter(message.id)
            ])
    }

    @Test
    func historyIsReadOnlyAndMissingServiceDoesNotStartAFlow() {
        let service = ReferenceLetterInquirySpy()
        let bridge = TanyaAIBridge(transport: FakeChatTransport(), services: .init(referenceLetter: service))
        bridge.replaceOrMerge([trigger()], conversationID: "conversation-a")
        #expect(bridge.referenceLetters["reference-message"]?.phase == .history)
        #expect(service.inquiryCount == 0)
        let unsupported = TanyaAIBridge(transport: FakeChatTransport())
        unsupported.apply(.message(trigger()))
        #expect(unsupported.referenceLetters.isEmpty)
    }

    @Test
    func changingConversationInvalidatesThePreviousInstance() async throws {
        let bridge = TanyaAIBridge(
            transport: FakeChatTransport(), services: .init(referenceLetter: ReferenceLetterInquirySpy())
        )
        bridge.replaceOrMerge([], conversationID: "conversation-a")
        bridge.apply(.message(trigger()))
        let old = try #require(bridge.referenceLetters["reference-message"])
        bridge.replaceOrMerge([], conversationID: "conversation-b")
        #expect(bridge.referenceLetters.isEmpty)
        #expect(old.phase == .cancelled)
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeFormTests {
    func trigger() -> ChatMessage {
        ChatMessage(
            id: "reference-message", seq: 2, author: .assistant, text: "Reference letter", status: .active,
            intent: .referenceLetter
        )
    }
}
