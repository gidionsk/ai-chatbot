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

    @Test
    func pendingSubmitDoesNotLockReplacementForm() async throws {
        let service = ReferenceLetterServiceDouble()
        let bridge = makeBridge(service).bridge
        var requests: [CheckedContinuation<Void, Never>] = []
        service.beforeSubmit = { await withCheckedContinuation { requests.append($0) } }
        defer { requests.forEach { $0.resume() } }

        ReferenceLetterServiceDouble.fill(try await openForm(in: bridge))
        let firstSubmit = Task { try await bridge.submitReferenceLetter(pin: "123456", messageID: "fresh") }
        await waitUntil { requests.count == 1 }
        try #require(requests.count == 1)
        #expect(bridge.isSubmittingReferenceLetter(messageID: "fresh"))

        ReferenceLetterServiceDouble.fill(try await openForm(in: bridge, conversationID: "next"))
        #expect(!bridge.isSubmittingReferenceLetter(messageID: "fresh"))
        let secondSubmit = Task { try await bridge.submitReferenceLetter(pin: "123456", messageID: "fresh") }
        await waitUntil { requests.count == 2 }
        try #require(requests.count == 2)

        requests.removeFirst().resume()
        let firstSucceeded = try await firstSubmit.value
        #expect(!firstSucceeded)
        #expect(bridge.isSubmittingReferenceLetter(messageID: "fresh"))

        requests.removeFirst().resume()
        let secondSucceeded = try await secondSubmit.value
        #expect(secondSucceeded)
        #expect(!bridge.isSubmittingReferenceLetter(messageID: "fresh"))
        #expect(service.submitCount == 2)
    }

    @Test
    func streamCompletionClosesOnlyItsSheet() async throws {
        try await assertCompletionClosesOnlyItsSheet { bridge, receipt in
            bridge.apply(.message(receipt))
        }
    }

    @Test
    func historyCompletionClosesOnlyItsSheet() async throws {
        try await assertCompletionClosesOnlyItsSheet { bridge, receipt in
            bridge.replaceOrMerge([receipt], conversationID: "chat")
        }
    }

    private func assertCompletionClosesOnlyItsSheet(
        deliverReceipt: (TanyaAIBridge, ChatMessage) -> Void
    ) async throws {
        let service = ReferenceLetterServiceDouble()
        let bridge = makeBridge(service).bridge
        ReferenceLetterServiceDouble.fill(try await openForm(in: bridge))
        let pin = ChatSheet.referenceLetterPIN(messageID: "fresh")
        let choices = ChatSheet.referenceLetterChoices(messageID: "fresh", field: .accounts)
        #expect(pin.afterReferenceLetterCompletion(in: bridge.messages) == pin)
        #expect(choices.afterReferenceLetterCompletion(in: bridge.messages) == choices)

        let receipt = message(id: "fresh", seq: 2).receipted(successID: "other-channel")
        deliverReceipt(bridge, receipt)

        #expect(pin.afterReferenceLetterCompletion(in: bridge.messages) == nil)
        #expect(choices.afterReferenceLetterCompletion(in: bridge.messages) == nil)
        let other = ChatSheet.referenceLetterPIN(messageID: "other")
        #expect(other.afterReferenceLetterCompletion(in: bridge.messages) == other)
        let result = try await bridge.submitReferenceLetter(pin: "123456", messageID: "fresh")
        #expect(!result)
        #expect(service.submitCount == 0)
    }

    private func makeBridge(_ service: ReferenceLetterServiceDouble) -> ReferenceLetterBridgeFixture {
        let transport = FakeChatTransport()
        let bridge = TanyaAIBridge(
            transport: transport,
            services: TanyaAIIntentServices(referenceLetter: service)
        )
        return ReferenceLetterBridgeFixture(transport: transport, bridge: bridge)
    }

    private func openForm(
        in bridge: TanyaAIBridge,
        conversationID: String = "chat"
    ) async throws -> ReferenceLetterForm {
        bridge.replaceOrMerge([], conversationID: conversationID)
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
