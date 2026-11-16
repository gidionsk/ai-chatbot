//
//  ReferenceLetterServiceAdapterTests.swift
//  TanyaAISandboxTests
//
//  Created by Wendra on 16/11/26.
//

import Foundation
import TanyaAI
import Testing

@testable import Tanya_AI_Sandbox

@MainActor
struct ReferenceLetterServiceAdapterTests {
    @Test
    func realDecoderMapsInquiryAndSeparatesEncryptedEmail() async throws {
        let fixture = AdapterFixture()
        let inquiry = try await fixture.adapter().inquiry()
        #expect(inquiry.purposes.first?.id == "001")
        #expect(inquiry.sourceAccounts.first?.subtitle == "IDR 1.000.000")
        #expect(inquiry.decryptedEmail == "plain@example.com")
        #expect(inquiry.encryptedEmail == "ciphertext-email")
        #expect(fixture.decryptCalls == ["ciphertext-email"])
        #expect(fixture.calls == [.inquiry])
        #expect(ReferenceLetterEndpoint.inquiry.method == "GET")
        #expect(ReferenceLetterEndpoint.acknowledge.method == "POST")
    }

    @Test
    func verifyUsesTheHostOTPAndACKUsesTheVerifiedToken() async throws {
        let fixture = AdapterFixture()
        let adapter = fixture.adapter()
        let request = try await fixture.request()
        fixture.calls = []
        let verification = try await adapter.verify(pin: "123456")
        let pinBody = try #require(fixture.verifyBody)
        let pinJSON = try #require(JSONSerialization.jsonObject(with: pinBody) as? [String: String])
        #expect(pinJSON["otpCode"] == "host-generated-otp")
        #expect(pinJSON["sequenceNumber"] == "4")
        #expect(pinJSON["challengeCode"] == nil)
        let receipt = try await adapter.acknowledge(request, verification: verification)
        #expect(fixture.calls == [.verifyPIN, .acknowledge])
        #expect(receipt.title.isEmpty)
        #expect(receipt.message == "Notes supplied by ACK")
        let ackBody = try #require(fixture.ackBody)
        let ackJSON = try #require(JSONSerialization.jsonObject(with: ackBody) as? [String: Any])
        #expect(ackJSON["responseCodeOTP"] as? String == "host-ack-token")
        #expect(ackJSON["email"] as? String == "ciphertext-email")
        #expect(ackJSON["onlineSessionId"] as? String == "session-id")
        #expect(ackJSON["pin"] == nil)
        #expect(ackJSON["otpCode"] == nil)
        let purpose = try #require(ackJSON["purpose"] as? [String: String])
        #expect(purpose == ["code": "001", "value": "VISA"])
        let accounts = try #require(ackJSON["sourceAccounts"] as? [[String: String]])
        #expect(accounts == [["code": "a", "value": "Account A", "description": "IDR 1.000.000"]])
        #expect(ackJSON["isShowInvestmentFund"] as? Bool == false)
        #expect(ackJSON["address"] as? String == "Address")
    }

    @Test(arguments: ["05516", "05005", "05000", "05006"])
    func businessErrorsAreNotTreatedAsHTTP200Success(code: String) async throws {
        let fixture = AdapterFixture()
        fixture.verifyCode = code
        do {
            _ = try await fixture.adapter().verify(pin: "123456")
            Issue.record("Verifikasi error harus throw")
        } catch let error as ReferenceLetterServiceError {
            switch (code, error) {
            case ("05516", .invalidPIN(let message)), ("05005", .blockedPIN(let message)),
                ("05000", .verification(let message)), ("05006", .verification(let message)):
                #expect(message == "Pesan BE")
            default:
                Issue.record("Pemetaan error keliru")
            }
        }
        #expect(fixture.calls == [.verifyPIN])
    }

    @Test
    func aSnapshotWithoutVerificationCannotHitACK() async throws {
        let fixture = AdapterFixture()
        let request = try await fixture.request()
        fixture.calls = []
        do {
            _ = try await fixture.adapter().acknowledge(
                request, verification: ReferenceLetterVerification(responseCodeOTP: "")
            )
            Issue.record("ACK tanpa verifikasi harus ditolak")
        } catch is ReferenceLetterServiceError {}
        #expect(fixture.calls.isEmpty)
    }
}

@MainActor
private final class AdapterFixture {
    var calls: [ReferenceLetterEndpoint] = []
    var decryptCalls: [String] = []
    var verifyCode = "00000"
    var verifyBody: Data?
    var ackBody: Data?

    func adapter() -> ReferenceLetterServiceAdapter {
        ReferenceLetterServiceAdapter(
            locale: Locale(identifier: "id"),
            fallbackMessage: "Fallback",
            send: { try self.response($0, body: $1) },
            preparePIN: { _ in
                ReferenceLetterPreparedPIN(
                    request: ReferenceLetterPINRequest(
                        otpCode: "host-generated-otp", appliNumber: "1", sequenceNumber: "4"
                    ),
                    verification: ReferenceLetterVerification(responseCodeOTP: "host-ack-token")
                )
            },
            decryptEmail: {
                self.decryptCalls.append($0)
                return "plain@example.com"
            }
        )
    }

    func request() async throws -> ReferenceLetterRequest {
        let inquiry = try await adapter().inquiry()
        var draft = ReferenceLetterDraft(inquiry: inquiry)
        draft.destination = "Embassy"
        draft.accountCodes = ["a"]
        draft.currencyCode = "001"
        draft.languageCode = "IN"
        return try #require(ReferenceLetterRequest(inquiry: inquiry, draft: draft))
    }

    func response(_ endpoint: ReferenceLetterEndpoint, body: Data?) throws -> Data {
        calls.append(endpoint)
        switch endpoint {
        case .inquiry:
            return Data(Self.inquiry.utf8)
        case .verifyPIN:
            verifyBody = body
            return try JSONSerialization.data(withJSONObject: [
                "response_code": verifyCode, "response_desc_en": "English message", "response_desc_id": "Pesan BE"
            ])
        case .acknowledge:
            ackBody = body
            return Data(#"{"response_code":"00000","data":{"title":"","message":"Notes supplied by ACK"}}"#.utf8)
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
