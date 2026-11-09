//
//  IntentRouter.swift
//  TanyaAI
//
//  Created by Gidion on 10/11/26.
//

/// Memilih handler berdasarkan nama intent tanpa mengikat SDK pada navigasi host.
@MainActor
public final class IntentRouter {
    private var handlers: [String: any IntentHandler] = [:]

    public init() {}

    public func register(_ handler: any IntentHandler) {
        handlers[handler.intentName] = handler
    }

    public func unregister(intentName: String) {
        handlers.removeValue(forKey: intentName)
    }

    public func route(_ context: IntentContext) -> IntentResult {
        guard let handler = handlers[context.name] else {
            return .unsupported
        }
        return handler.handle(context)
    }
}
