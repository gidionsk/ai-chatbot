//
//  SandboxReferenceLetterService.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/11/26.
//

import Foundation
import TanyaAI

@MainActor
final class SandboxHostServices: TanyaAIHostServices {
    private let onAcknowledgementError: (Error) -> Void

    private(set) lazy var referenceLetter: ReferenceLetterService? = {
        let options = SandboxOptions.current
        guard options.isFormDemo else { return nil }
        return SandboxReferenceLetterService(
            locale: options.locale ?? .current,
            onAcknowledgementError: onAcknowledgementError
        )
    }()

    init(onAcknowledgementError: @escaping (Error) -> Void) {
        self.onAcknowledgementError = onAcknowledgementError
    }
}

/// Service dummy untuk menjalankan alur chat yang sama tanpa jaringan Byon.
@MainActor
private final class SandboxReferenceLetterService: ReferenceLetterService {
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
            throw ReferenceLetterSubmissionError.pinVerification(message: nil, isBlocked: true)
        }
        guard pin == SandboxOptions.formPin else {
            throw ReferenceLetterSubmissionError.pinVerification(
                message: String(SandboxCopy.formPinWrong, locale: locale),
                isBlocked: false
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
