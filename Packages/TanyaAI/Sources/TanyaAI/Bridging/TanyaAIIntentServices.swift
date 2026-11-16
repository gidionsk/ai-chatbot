//
//  TanyaAIIntentServices.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Service Byon opsional, dipasok host. Terpisah dari transport chat-gateway dan tidak di-retry bridge.
public struct TanyaAIIntentServices {
    public var referenceLetter: ReferenceLetterService?

    public init(referenceLetter: ReferenceLetterService? = nil) {
        self.referenceLetter = referenceLetter
    }
}
