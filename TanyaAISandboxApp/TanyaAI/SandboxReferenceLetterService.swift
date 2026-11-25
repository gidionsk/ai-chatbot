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
    private let onAcknowledgementError: (Error) -> Void

    init(locale: Locale, onAcknowledgementError: @escaping (Error) -> Void) {
        self.locale = locale
        self.onAcknowledgementError = onAcknowledgementError
    }

    func inquiry() async throws -> ReferenceLetterInquiry {
        let options = SandboxOptions.current
        if options.isFormInquirySlow || options.isFormInquiryFailing {
            try await Task.sleep(nanoseconds: SandboxOptions.formInquiryNanoseconds)
        }
        if options.isFormInquiryFailing {
            throw URLError(.badServerResponse)
        }
        return SandboxGatewayFrames.referenceLetterInquiry
    }

    func submit(_ request: ReferenceLetterRequest, pin: String) async throws -> ReferenceLetterReceipt {
        try await Task.sleep(nanoseconds: SandboxOptions.formVerifyNanoseconds)
        if SandboxOptions.current.isFormPINBlocked {
            throw ReferenceLetterSubmissionError.pinVerification(
                message: String(SandboxCopy.formPinBlocked, locale: locale)
            )
        }
        guard pin == SandboxOptions.formPin else {
            throw ReferenceLetterSubmissionError.pinVerification(
                message: String(SandboxCopy.formPinWrong, locale: locale)
            )
        }
        if SandboxOptions.current.isFormAckFailing {
            throw ReferenceLetterSubmissionError.acknowledgement(URLError(.badServerResponse))
        }
        return ReferenceLetterReceipt(
            title: String(),
            message: SandboxGatewayFrames.referenceLetterACKMessage,
            successID: request.onlineSessionID
        )
    }

    func presentAcknowledgementError(_ error: Error) {
        onAcknowledgementError(error)
    }
}
