//
//  TanyaAIIntentServices.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Service Byon opsional, dipasok host. Terpisah dari transport chat-gateway dan tidak di-retry bridge.
public struct TanyaAIIntentServices {
    public var referenceLetter: ReferenceLetterService?
    public var referenceLetterSubmission: ReferenceLetterSubmissionService?

    public init(
        referenceLetter: ReferenceLetterService? = nil,
        referenceLetterSubmission: ReferenceLetterSubmissionService? = nil
    ) {
        self.referenceLetter = referenceLetter
        self.referenceLetterSubmission = referenceLetterSubmission
    }
}
