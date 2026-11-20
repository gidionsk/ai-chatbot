//
//  SandboxReferenceLetterService.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/11/26.
//

import Foundation
import TanyaAI

/// Service dummy untuk menjalankan alur chat yang sama tanpa jaringan Byon.
@MainActor
final class SandboxReferenceLetterService: ReferenceLetterService {
    private let locale: Locale

    init(locale: Locale) {
        self.locale = locale
    }

    func inquiry() async throws -> ReferenceLetterInquiry {
        SandboxGatewayFrames.referenceLetterInquiry
    }

    func submit(_ request: ReferenceLetterRequest, pin: String) async throws -> ReferenceLetterReceipt {
        try await Task.sleep(nanoseconds: SandboxOptions.formVerifyNanoseconds)
        guard pin == SandboxOptions.formPin else {
            throw SandboxReferenceLetterError(errorDescription: String(SandboxCopy.formPinWrong, locale: locale))
        }
        return ReferenceLetterReceipt(
            title: String(),
            message: SandboxGatewayFrames.referenceLetterACKMessage,
            successID: request.onlineSessionID
        )
    }
}

private struct SandboxReferenceLetterError: LocalizedError {
    let errorDescription: String?
}
