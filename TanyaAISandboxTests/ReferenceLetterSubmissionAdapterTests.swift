//
//  ReferenceLetterSubmissionAdapterTests.swift
//  TanyaAISandboxTests
//
//  Created by Wendra on 17/11/26.
//

import Foundation
import TanyaAI
import Testing

@testable import Tanya_AI_Sandbox

@MainActor
struct ReferenceLetterSubmissionAdapterTests {
    @Test
    func authorizationDelegatesToTheHostWithoutAnExtraHTTPRequest() async throws {
        let fixture = ReferenceLetterAdapterFixture()
        let result = try await fixture.submissionAdapter().authorize()
        #expect(result?.responseCodeOTP == "host-ack-token")
        #expect(fixture.authorizationCount == 1)
        #expect(fixture.calls.isEmpty)
    }

    @Test
    func hostCancellationRemainsCancellation() async throws {
        let fixture = ReferenceLetterAdapterFixture()
        fixture.isAuthorizationCancelled = true
        let result = try await fixture.submissionAdapter().authorize()
        #expect(result == nil)
        #expect(fixture.calls.isEmpty)
    }

    @Test
    func ACKBodyPreservesBackendValuesAndTheHostAuthorization() async throws {
        let fixture = ReferenceLetterAdapterFixture()
        let request = try await fixture.request()
        fixture.calls = []
        let adapter = fixture.submissionAdapter()
        let authorization = try #require(try await adapter.authorize())
        let receipt = try await adapter.acknowledge(request, authorization: authorization)
        #expect(fixture.calls == [.acknowledge])
        #expect(receipt.message == "Notes supplied by ACK")
        let body = try #require(fixture.ackBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["responseCodeOTP"] as? String == "host-ack-token")
        #expect(json["email"] as? String == "ciphertext-email")
        #expect(json["onlineSessionId"] as? String == "session-id")
        #expect(json["pin"] == nil)
        #expect(json["otpCode"] == nil)
        #expect(json["address"] as? String == "Address")
        #expect(json["isShowInvestmentFund"] as? Bool == false)
        let accounts = try #require(json["sourceAccounts"] as? [[String: String]])
        #expect(accounts == [["code": "a", "value": "Account A", "description": "IDR 1.000.000"]])
        #expect(ReferenceLetterEndpoint.acknowledge.method == "POST")
    }

    @Test
    func missingAuthorizationCannotHitACK() async throws {
        let fixture = ReferenceLetterAdapterFixture()
        let request = try await fixture.request()
        fixture.calls = []
        do {
            _ = try await fixture.submissionAdapter().acknowledge(
                request, authorization: ReferenceLetterAuthorization(responseCodeOTP: "")
            )
            Issue.record("ACK without authorization must fail")
        } catch {}
        #expect(fixture.calls.isEmpty)
    }

    @Test
    func explicitBusinessRejectionIsDistinctFromAnUnknownACKOutcome() async throws {
        let fixture = ReferenceLetterAdapterFixture()
        let request = try await fixture.request()
        fixture.ackCode = "99999"
        do {
            _ = try await fixture.submissionAdapter().acknowledge(
                request, authorization: ReferenceLetterAuthorization(responseCodeOTP: "host-result")
            )
            Issue.record("Business error must fail")
        } catch ReferenceLetterServiceError.rejected(let message) {
            #expect(message == "BE message")
        }
        fixture.ackCode = "00000"
        fixture.isReceiptMissing = true
        do {
            _ = try await fixture.submissionAdapter().acknowledge(
                request, authorization: ReferenceLetterAuthorization(responseCodeOTP: "host-result")
            )
            Issue.record("Missing receipt must not show success")
        } catch let error as URLError {
            #expect(error.code == .cannotParseResponse)
        }
    }
}
