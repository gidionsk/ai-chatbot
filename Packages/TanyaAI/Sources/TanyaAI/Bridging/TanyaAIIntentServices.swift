//
//  TanyaAIIntentServices.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Service inquiry opsional, disediakan host dan terpisah dari transport chat-gateway.
public struct TanyaAIIntentServices {
    public var referenceLetter: ReferenceLetterService?

    public init(referenceLetter: ReferenceLetterService? = nil) {
        self.referenceLetter = referenceLetter
    }
}
