//
//  ReferenceLetterRequestTests.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

struct ReferenceLetterRequestTests {
    @Test
    func ACKBodyPreservesBackendValuesAndUsesEncryptedEmail() throws {
        let request = try #require(
            ReferenceLetterRequest(inquiry: ReferenceLetterFixture.inquiry, draft: ReferenceLetterFixture.draft)
        )
        let authorized = request.authorized(with: ReferenceLetterVerification(responseCodeOTP: "response-token"))
        let body = try JSONEncoder().encode(authorized)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["email"] as? String == "ciphertext-email")
        #expect(json["onlineSessionId"] as? String == "session-id")
        #expect(json["responseCodeOTP"] as? String == "response-token")
        #expect(json["otpCode"] == nil)
        #expect(json["pin"] == nil)
        let purpose = try #require(json["purpose"] as? [String: String])
        #expect(purpose == ["code": "001", "value": "VISA"])
        let accounts = try #require(json["sourceAccounts"] as? [[String: String]])
        #expect(accounts == [["code": "a", "value": "Account A", "description": "IDR 1.000.000"]])
        #expect(json["isShowInvestmentFund"] as? Bool == false)
        #expect(json["address"] as? String == "Address from inquiry")
    }

    @Test
    func invalidDraftCannotBecomeAnACKRequest() {
        let draft = ReferenceLetterDraft(inquiry: ReferenceLetterFixture.inquiry)
        #expect(ReferenceLetterRequest(inquiry: ReferenceLetterFixture.inquiry, draft: draft) == nil)
    }
}
