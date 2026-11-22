//
//  TanyaAIBridgeReferenceLetterTests.swift
//  TanyaAITests
//
//  Created by Wendra on 22/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

@MainActor
@Suite(.serialized)
struct TanyaAIBridgeReferenceLetterTests {
    @Test
    func onlyNewStreamMessagesOpenForms() async throws {
        let service = ReferenceLetterServiceDouble()
        let fixture = makeBridge(service)
        let history = message(id: "history", seq: 1)
        let fresh = message(id: "fresh", seq: 2)
        fixture.bridge.replaceOrMerge([history], conversationID: "chat")
        fixture.bridge.apply(.message(history))
        #expect(fixture.bridge.referenceLetters.isEmpty)

        fixture.bridge.apply(.message(fresh))
        let first = try #require(fixture.bridge.referenceLetters[fresh.id])
        fixture.bridge.apply(.message(fresh))
        #expect(fixture.bridge.referenceLetters[fresh.id] === first)
        await waitUntil { first.inquiry != nil }
        #expect(service.inquiryCount == 1)
        #expect(fixture.bridge.referenceLetterLayouts[.message(fresh.id)] == first.layout)
    }

    @Test
    func submissionRequiresACurrentForm() async throws {
        let service = ReferenceLetterServiceDouble()
        let fixture = makeBridge(service)
        let missing = try await fixture.bridge.submitReferenceLetter(pin: "123456", messageID: "unknown")
        #expect(!missing)
        let form = try await openForm(in: fixture.bridge)
        ReferenceLetterServiceDouble.fill(form)
        service.beforeSubmit = { [weak bridge = fixture.bridge] in
            let duplicate = try? await bridge?.submitReferenceLetter(pin: "123456", messageID: "fresh")
            #expect(duplicate == false)
        }
        let valid = try await fixture.bridge.submitReferenceLetter(pin: "123456", messageID: "fresh")
        #expect(valid)
        #expect(service.submitCount == 1)
    }

    @Test
    func successMarksTheGatewayMessage() async throws {
        let service = ReferenceLetterServiceDouble()
        let fixture = makeBridge(service)
        let form = try await openForm(in: fixture.bridge)
        ReferenceLetterServiceDouble.fill(form)
        let result = try await fixture.bridge.submitReferenceLetter(pin: "123456", messageID: "fresh")
        #expect(result)
        await waitUntil { fixture.bridge.messages.first?.successID == "ref-1" }
        #expect(fixture.transport.calls.contains("success:fresh:ref-1"))
    }

    @Test(arguments: [false, true])
    func changingConversationDuringSubmitDropsResult(isAckFailure: Bool) async throws {
        let service = ReferenceLetterServiceDouble()
        let fixture = makeBridge(service)
        let form = try await openForm(in: fixture.bridge)
        ReferenceLetterServiceDouble.fill(form)
        service.beforeSubmit = { [weak bridge = fixture.bridge] in
            bridge?.replaceOrMerge([], conversationID: "next")
        }
        if isAckFailure {
            service.submitResult = .failure(
                ReferenceLetterSubmissionError.acknowledgement(URLError(.badServerResponse)))
        }
        let result = try await fixture.bridge.submitReferenceLetter(pin: "123456", messageID: "fresh")
        #expect(!result)
        #expect(fixture.bridge.referenceLetters.isEmpty)
        #expect(fixture.bridge.referenceLetterLayouts.isEmpty)
        #expect(!fixture.transport.calls.contains("success:fresh:ref-1"))
    }

    private func makeBridge(_ service: ReferenceLetterServiceDouble) -> ReferenceLetterBridgeFixture {
        let transport = FakeChatTransport()
        let bridge = TanyaAIBridge(
            transport: transport,
            services: TanyaAIIntentServices(referenceLetter: service)
        )
        return ReferenceLetterBridgeFixture(transport: transport, bridge: bridge)
    }

    private func openForm(in bridge: TanyaAIBridge) async throws -> ReferenceLetterForm {
        bridge.replaceOrMerge([], conversationID: "chat")
        let fresh = message(id: "fresh", seq: 2)
        bridge.apply(.message(fresh))
        let form = try #require(bridge.referenceLetters[fresh.id])
        await waitUntil { form.inquiry != nil }
        return form
    }

    private func message(id: String, seq: Int) -> ChatMessage {
        ChatMessage(
            id: id, seq: seq, author: .assistant, text: "Reference letter", status: .active, intent: .referenceLetter)
    }
}
