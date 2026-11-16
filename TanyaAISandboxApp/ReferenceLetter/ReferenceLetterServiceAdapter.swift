//
//  ReferenceLetterServiceAdapter.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 16/11/26.
//

import Foundation
import TanyaAI

/// Adapter inquiry pada project host, memakai service dan decrypt email existing.
/// Tidak memiliki credential/base URL, tidak log body/PIN, dan tidak me-retry request transaksi.
@MainActor
final class ReferenceLetterServiceAdapter: ReferenceLetterService {
    private let send: (ReferenceLetterEndpoint, Data?) async throws -> Data
    private let decryptEmail: (String) throws -> String
    private let fallbackMessage: String

    init(
        fallbackMessage: String,
        send: @escaping (ReferenceLetterEndpoint, Data?) async throws -> Data,
        decryptEmail: @escaping (String) throws -> String
    ) {
        self.fallbackMessage = fallbackMessage
        self.send = send
        self.decryptEmail = decryptEmail
    }

    func inquiry() async throws -> ReferenceLetterInquiry {
        let raw = try await send(.inquiry, nil)
        let response = try JSONDecoder().decode(
            ReferenceLetterWire.Envelope<ReferenceLetterWire.Inquiry>.self,
            from: raw
        )
        guard response.code == ReferenceLetterResponseCode.success.rawValue, let data = response.data,
            !data.onlineSessionId.isEmpty
        else { throw ReferenceLetterServiceError.rejected(response.message(fallback: fallbackMessage)) }
        return ReferenceLetterInquiry(
            introduction: data.introduction,
            purposes: data.purposes.map(\.option),
            documentFormats: data.documentFormats.map(\.option),
            sourceAccounts: data.sourceAccounts.map(\.option),
            currencies: data.currencies.map(\.option),
            languages: data.languages?.map(\.option) ?? [],
            address: data.address,
            decryptedEmail: try decryptEmail(data.email),
            encryptedEmail: data.email,
            onlineSessionID: data.onlineSessionId
        )
    }

}
