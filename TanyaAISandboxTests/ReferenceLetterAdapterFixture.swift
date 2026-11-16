//
//  ReferenceLetterAdapterFixture.swift
//  TanyaAISandboxTests
//
//  Created by Wendra on 17/11/26.
//

import Foundation
import TanyaAI
import Testing

@testable import Tanya_AI_Sandbox

@MainActor
final class ReferenceLetterAdapterFixture {
    var calls: [ReferenceLetterEndpoint] = []
    var decryptCalls: [String] = []
    var authorizationCount = Int.zero
    var isAuthorizationCancelled = false
    var isAuthorizationEmpty = false
    var ackCode = "00000"
    var isReceiptMissing = false
    var ackBody: Data?

    func inquiryAdapter() -> ReferenceLetterServiceAdapter {
        ReferenceLetterServiceAdapter(
            fallbackMessage: "Fallback",
            send: { try self.response($0, body: $1) },
            decryptEmail: {
                self.decryptCalls.append($0)
                return "plain@example.com"
            }
        )
    }

    func submissionAdapter() -> ReferenceLetterSubmissionAdapter {
        ReferenceLetterSubmissionAdapter(
            fallbackMessage: "Fallback",
            authorizeWithHost: {
                self.authorizationCount += 1
                if self.isAuthorizationCancelled { return nil }
                return ReferenceLetterAuthorization(responseCodeOTP: self.isAuthorizationEmpty ? "" : "host-ack-token")
            },
            send: { try self.response($0, body: $1) }
        )
    }

    func request() async throws -> ReferenceLetterRequest {
        let inquiry = try await inquiryAdapter().inquiry()
        var draft = ReferenceLetterDraft(inquiry: inquiry)
        draft.destination = "Embassy"
        draft.accountCodes = ["a"]
        draft.currencyCode = "001"
        draft.languageCode = "IN"
        return try #require(ReferenceLetterRequest(inquiry: inquiry, draft: draft))
    }

    private func response(_ endpoint: ReferenceLetterEndpoint, body: Data?) throws -> Data {
        calls.append(endpoint)
        switch endpoint {
        case .inquiry:
            return Data(Self.inquiry.utf8)
        case .acknowledge:
            ackBody = body
            var json: [String: Any] = ["response_code": ackCode, "responseDescription": "BE message"]
            if !isReceiptMissing { json["data"] = ["title": "", "message": "Notes supplied by ACK"] }
            return try JSONSerialization.data(withJSONObject: json)
        }
    }

    private static let inquiry = #"""
        {"response_code":"00000","data":{
            "introduction":"Introduction",
            "purposes":[{"code":"001","value":"VISA"}],
            "documentFormats":[{"code":"SOFTCOPY","value":"Softcopy"}],
            "sourceAccounts":[{"code":"a","value":"Account A","description":"IDR 1.000.000"}],
            "currencies":[{"code":"001","value":"IDR"}],
            "languages":[{"code":"IN","value":"INDONESIA"}],
            "address":"Address", "email":"ciphertext-email", "onlineSessionId":"session-id"
        }}
        """#
}
