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

    private static func data(_ fixture: SandboxFixtureFile) throws -> Data {
        guard let url = fixture.url else { throw CocoaError(.fileNoSuchFile) }
        return try Data(contentsOf: url)
    }
}
