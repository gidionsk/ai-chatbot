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
    func snapshotPreservesBackendValuesAndUsesEncryptedEmail() throws {
        let request = try #require(
            ReferenceLetterRequest(inquiry: ReferenceLetterFixture.inquiry, draft: ReferenceLetterFixture.draft)
        )
        #expect(request.email == "ciphertext-email")
        #expect(request.onlineSessionId == "session-id")
        #expect(request.purpose.code == "001")
        #expect(request.purpose.value == "VISA")
        #expect(request.sourceAccounts.map(\.code) == ["a"])
        #expect(request.sourceAccounts.first?.description == "IDR 1.000.000")
        #expect(request.isShowInvestmentFund == false)
        #expect(request.address == "Address from inquiry")
    }

    @Test
    func invalidDraftCannotBecomeAnACKRequest() {
        let draft = ReferenceLetterDraft(inquiry: ReferenceLetterFixture.inquiry)
        #expect(ReferenceLetterRequest(inquiry: ReferenceLetterFixture.inquiry, draft: draft) == nil)
    }
}
