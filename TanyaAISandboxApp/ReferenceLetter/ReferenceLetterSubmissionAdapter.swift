//
//  ReferenceLetterSubmissionAdapter.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 17/11/26.
//

import Foundation
import TanyaAI

/// Adapter submit milik project host. Pemanggil memasang coordinator PIN existing pada authorizeWithHost.
/// Tidak mendefinisikan endpoint PIN, membuat OTP, atau mengirim verifikasi PIN lagi.
@MainActor
final class ReferenceLetterSubmissionAdapter: ReferenceLetterSubmissionService {
    private let authorizeWithHost: () async throws -> ReferenceLetterAuthorization?
    private let send: (ReferenceLetterEndpoint, Data?) async throws -> Data
    private let fallbackMessage: String

    init(
        fallbackMessage: String,
        authorizeWithHost: @escaping () async throws -> ReferenceLetterAuthorization?,
        send: @escaping (ReferenceLetterEndpoint, Data?) async throws -> Data
    ) {
        self.fallbackMessage = fallbackMessage
        self.authorizeWithHost = authorizeWithHost
        self.send = send
    }

    func authorize() async throws -> ReferenceLetterAuthorization? {
        try await authorizeWithHost()
    }

    func acknowledge(
        _ request: ReferenceLetterRequest,
        authorization: ReferenceLetterAuthorization
    ) async throws -> ReferenceLetterReceipt {
        guard !authorization.responseCodeOTP.isEmpty else {
            throw ReferenceLetterServiceError.authorization(fallbackMessage)
        }
        let body = try JSONEncoder().encode(ReferenceLetterACKRequest(request, authorization: authorization))
        let raw = try await send(.acknowledge, body)
        let response = try JSONDecoder().decode(
            ReferenceLetterWire.Envelope<ReferenceLetterWire.Receipt>.self,
            from: raw
        )
        guard response.code == ReferenceLetterResponseCode.success.rawValue else {
            throw ReferenceLetterServiceError.rejected(response.message(fallback: fallbackMessage))
        }
        guard let data = response.data else { throw URLError(.cannotParseResponse) }
        return ReferenceLetterReceipt(title: data.title, message: data.message)
    }
}
