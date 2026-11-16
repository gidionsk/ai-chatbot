//
//  SandboxReferenceLetterService.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 16/11/26.
//

import Foundation
import TanyaAI

/// HTTP/token/decrypt tiruan untuk demo. Adapter dan decoder produksi tetap dijalankan; tidak ada koneksi bank.
@MainActor
final class SandboxReferenceLetterService {
    private var verificationCount = Int.zero

    static func make(locale: Locale) -> ReferenceLetterServiceAdapter {
        let fixture = SandboxReferenceLetterService()
        return ReferenceLetterServiceAdapter(
            locale: locale,
            fallbackMessage: String(SandboxCopy.referenceServiceFailed, locale: locale),
            send: { try fixture.response(for: $0, body: $1, locale: locale) },
            preparePIN: { _ in
                // Stub token, bukan algoritma pembuat OTP. Host nyata wajib memakai token service existing.
                ReferenceLetterPreparedPIN(
                    request: ReferenceLetterPINRequest(otpCode: "fixture-otp", appliNumber: "1", sequenceNumber: "4"),
                    verification: ReferenceLetterVerification(responseCodeOTP: "fixture-response-otp")
                )
            },
            decryptEmail: { encrypted in
                // Lookup fixture eksplisit, bukan implementasi dekripsi. Tidak menerima ciphertext produksi.
                guard encrypted == SandboxOptions.referenceEncryptedEmail else { throw URLError(.cannotDecodeRawData) }
                return SandboxOptions.referenceDecryptedEmail
            }
        )
    }
}

// MARK: - Helpers

private extension SandboxReferenceLetterService {
    func response(for endpoint: ReferenceLetterEndpoint, body: Data?, locale: Locale) throws -> Data {
        switch endpoint {
        case .inquiry:
            return try data(.referenceLetterInquiry)
        case .verifyPIN:
            verificationCount += 1
            let isInvalid = SandboxOptions.current.isReferencePINError && verificationCount == 1
            let message = String(SandboxCopy.referenceInvalidPIN, locale: locale)
            return try JSONSerialization.data(withJSONObject: [
                "response_code": isInvalid ? "05516" : "00000",
                "response_desc_en": message,
                "response_desc_id": message
            ])
        case .acknowledge:
            if SandboxOptions.current.isReferenceACKTimeout { throw URLError(.timedOut) }
            guard body != nil else { throw URLError(.cannotParseResponse) }
            return try data(.referenceLetterACK)
        }
    }

    func data(_ fixture: SandboxFixtureFile) throws -> Data {
        guard let url = fixture.url else { throw CocoaError(.fileNoSuchFile) }
        return try Data(contentsOf: url)
    }
}
