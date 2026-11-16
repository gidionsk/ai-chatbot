//
//  SandboxReferenceLetterService.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 16/11/26.
//

import Foundation
import TanyaAI

/// Fixture inquiry dan ACK melalui adapter project host. Tidak ada koneksi bank atau implementasi PIN baru.
@MainActor
enum SandboxReferenceLetterService {
    static func inquiry(locale: Locale) -> ReferenceLetterServiceAdapter {
        ReferenceLetterServiceAdapter(
            fallbackMessage: String(SandboxCopy.referenceServiceFailed, locale: locale),
            send: { _, _ in try data(.referenceLetterInquiry) },
            decryptEmail: { encrypted in
                guard encrypted == SandboxOptions.referenceEncryptedEmail else { throw URLError(.cannotDecodeRawData) }
                return SandboxOptions.referenceDecryptedEmail
            }
        )
    }

    static func submission(locale: Locale) -> ReferenceLetterSubmissionAdapter {
        ReferenceLetterSubmissionAdapter(
            fallbackMessage: String(SandboxCopy.referenceServiceFailed, locale: locale),
            authorizeWithHost: {
                // Callback fixture saja. Project utama memasang flow PIN + verifikasi existing di sini.
                if SandboxOptions.current.isReferenceAuthorizationCancelled { return nil }
                if SandboxOptions.current.isReferenceAuthorizationError {
                    throw ReferenceLetterServiceError.authorization(
                        String(SandboxCopy.referenceAuthorizationFailed, locale: locale)
                    )
                }
                return ReferenceLetterAuthorization(responseCodeOTP: SandboxOptions.referenceAuthorizationToken)
            },
            send: { _, body in
                if SandboxOptions.current.isReferenceACKTimeout { throw URLError(.timedOut) }
                guard body != nil else { throw URLError(.cannotParseResponse) }
                return try data(.referenceLetterACK)
            }
        )
    }

    private static func data(_ fixture: SandboxFixtureFile) throws -> Data {
        guard let url = fixture.url else { throw CocoaError(.fileNoSuchFile) }
        return try Data(contentsOf: url)
    }
}
