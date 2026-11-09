//
//  IntentRouterTests.swift
//  TanyaAI
//
//  Created by Gidion on 10/11/26.
//

import Testing

@testable import TanyaAI

@MainActor
struct IntentRouterTests {
    @Test
    func unknownIntentIsUnsupported() {
        let router = IntentRouter()
        #expect(router.route(IntentContext(name: "unknown")) == .unsupported)
    }

    @Test
    func registeredHandlerReceivesParameters() {
        let router = IntentRouter()
        let handler = StubIntentHandler(intentName: "bank_reference_letter", result: .render(
            IntentContext(name: "bank_reference_letter")))
        router.register(handler)
        let context = IntentContext(name: "bank_reference_letter", parameters: ["format": "softcopy"])

        #expect(router.route(context) == .render(IntentContext(name: "bank_reference_letter")))
        #expect(handler.lastContext == context)
    }

    @Test
    func unregisterRemovesHandler() {
        let router = IntentRouter()
        router.register(StubIntentHandler(intentName: "navigation", result: .unsupported))
        router.unregister(intentName: "navigation")

        #expect(router.route(IntentContext(name: "navigation")) == .unsupported)
    }

    @Test
    func laterRegistrationReplacesPreviousHandler() {
        let router = IntentRouter()
        let context = IntentContext(name: "navigation")
        router.register(StubIntentHandler(intentName: "navigation", result: .unsupported))
        router.register(StubIntentHandler(intentName: "navigation", result: .navigate(context)))

        #expect(router.route(context) == .navigate(context))
    }
}

@MainActor
private final class StubIntentHandler: IntentHandler {
    let intentName: String
    let result: IntentResult
    private(set) var lastContext: IntentContext?

    init(intentName: String, result: IntentResult) {
        self.intentName = intentName
        self.result = result
    }

    func handle(_ context: IntentContext) -> IntentResult {
        lastContext = context
        return result
    }
}
