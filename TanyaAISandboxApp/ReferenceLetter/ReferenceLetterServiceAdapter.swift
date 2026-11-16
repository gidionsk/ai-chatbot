//
//  ReferenceLetterServiceAdapter.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 16/11/26.
//

import DesignKit
import Foundation
import TanyaAI

/// Adapter contract BE; host menyuntikkan HTTP existing, generator OTP, dan decrypt email existing.
/// Tidak memiliki credential/base URL, tidak log body/PIN, dan tidak me-retry request transaksi.
@MainActor
final class ReferenceLetterServiceAdapter: ReferenceLetterService {
    private let send: (ReferenceLetterEndpoint, Data?) async throws -> Data
    private let preparePIN: (String) async throws -> ReferenceLetterPreparedPIN
    private let decryptEmail: (String) throws -> String
    private let locale: Locale
    private let fallbackMessage: String

    init(
        locale: Locale,
        fallbackMessage: String,
        send: @escaping (ReferenceLetterEndpoint, Data?) async throws -> Data,
        preparePIN: @escaping (String) async throws -> ReferenceLetterPreparedPIN,
        decryptEmail: @escaping (String) throws -> String
    ) {
        self.locale = locale
        self.fallbackMessage = fallbackMessage
        self.send = send
        self.preparePIN = preparePIN
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
        else { throw ReferenceLetterServiceError.rejected(response.message(locale: locale, fallback: fallbackMessage)) }
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

    func verify(pin: String) async throws -> ReferenceLetterVerification {
        guard TransactionPINRules.isValid(pin) else { throw ReferenceLetterServiceError.verification(fallbackMessage) }
        let prepared = try await preparePIN(pin)
        guard !prepared.verification.responseCodeOTP.isEmpty else {
            throw ReferenceLetterServiceError.verification(fallbackMessage)
        }
        let body = try JSONEncoder().encode(prepared.request)
        let raw = try await send(.verifyPIN, body)
        let response = try JSONDecoder().decode(ReferenceLetterWire.Envelope<ReferenceLetterWire.Empty>.self, from: raw)
        let message = response.message(locale: locale, fallback: fallbackMessage)
        switch ReferenceLetterResponseCode(rawValue: response.code) {
        case .success: return prepared.verification
        case .invalidPIN: throw ReferenceLetterServiceError.invalidPIN(message)
        case .blockedPIN: throw ReferenceLetterServiceError.blockedPIN(message)
        default: throw ReferenceLetterServiceError.verification(message)
        }
    }

    func acknowledge(
        _ request: ReferenceLetterRequest,
        verification: ReferenceLetterVerification
    ) async throws -> ReferenceLetterReceipt {
        guard !verification.responseCodeOTP.isEmpty else { throw ReferenceLetterServiceError.rejected(fallbackMessage) }
        let body = try JSONEncoder().encode(ReferenceLetterACKRequest(request, verification: verification))
        let raw = try await send(.acknowledge, body)
        let response = try JSONDecoder().decode(
            ReferenceLetterWire.Envelope<ReferenceLetterWire.Receipt>.self,
            from: raw
        )
        guard response.code == ReferenceLetterResponseCode.success.rawValue else {
            throw ReferenceLetterServiceError.rejected(response.message(locale: locale, fallback: fallbackMessage))
        }
        guard let data = response.data else { throw URLError(.cannotParseResponse) }
        return ReferenceLetterReceipt(title: data.title, message: data.message)
    }
}
