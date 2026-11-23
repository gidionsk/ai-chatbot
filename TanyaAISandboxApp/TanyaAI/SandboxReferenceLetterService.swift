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
    private let options: SandboxOptions
    private let locale: Locale
    private let onHostSheetRequested: (String) -> Void

    private init(options: SandboxOptions, onHostSheetRequested: @escaping (String) -> Void) {
        self.options = options
        locale = options.locale ?? .current
        self.onHostSheetRequested = onHostSheetRequested
    }

    static func make(
        options: SandboxOptions,
        onHostSheetRequested: @escaping (String) -> Void
    ) -> SandboxReferenceLetterService? {
        guard options.isFormDemo else { return nil }
        return SandboxReferenceLetterService(options: options, onHostSheetRequested: onHostSheetRequested)
    }

    func inquiry() async throws -> ReferenceLetterInquiry {
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
        if options.isFormPINBlocked {
            throw ReferenceLetterSubmissionError.pinVerification(message: nil, isBlocked: true)
        }
        guard pin == SandboxOptions.formPin else {
            throw ReferenceLetterSubmissionError.pinVerification(
                message: String(SandboxCopy.formPinWrong, locale: locale),
                isBlocked: false
            )
        }
        if options.isFormAckFailing {
            throw ReferenceLetterSubmissionError.acknowledgement(URLError(.badServerResponse))
        }
        return ReferenceLetterReceipt(
            title: String(),
            message: SandboxGatewayFrames.referenceLetterACKMessage,
            successID: request.onlineSessionID
        )
    }

    func presentAcknowledgementError(_ error: Error) {
        onHostSheetRequested(String(SandboxCopy.formAckFailure, locale: locale))
    }
}
