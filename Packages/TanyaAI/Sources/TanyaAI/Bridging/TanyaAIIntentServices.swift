//
//  TanyaAIIntentServices.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

/// Opt-in host untuk intent yang memakai service di luar chat gateway.
public struct TanyaAIIntentServices {
    public let referenceLetter: (any ReferenceLetterService)?

    public init(referenceLetter: (any ReferenceLetterService)? = nil) {
        self.referenceLetter = referenceLetter
    }
}
