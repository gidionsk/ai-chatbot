//
//  ReferenceLetterInquiryTests.swift
//  TanyaAITests
//
//  Created by Wendra on 17/11/26.
//

import Testing

@testable import TanyaAI

struct ReferenceLetterInquiryTests {
    @Test
    func inquiryPreservesHostChoiceOrder() {
        let choices = [FormOption(code: "choice-z", title: "Last"), FormOption(code: "choice-a", title: "First")]
        let inquiry = ReferenceLetterInquiry(
            introduction: String(),
            purposes: choices,
            documentFormats: choices,
            sourceAccounts: choices,
            currencies: choices,
            languages: choices,
            address: String(),
            decryptedEmail: String(),
            encryptedEmail: String(),
            onlineSessionID: String()
        )
        for options in [
            inquiry.purposes,
            inquiry.documentFormats,
            inquiry.sourceAccounts,
            inquiry.currencies,
            inquiry.languages
        ] {
            #expect(options.map(\.code) == ["choice-z", "choice-a"])
        }
    }

    @Test
    func inquiryCanRepresentEmptyChoicesAndAnOmittedLanguageList() {
        let inquiry = ReferenceLetterInquiry(
            introduction: String(),
            purposes: [],
            documentFormats: [],
            sourceAccounts: [],
            currencies: [],
            address: String(),
            decryptedEmail: String(),
            encryptedEmail: String(),
            onlineSessionID: String()
        )
        #expect(inquiry.purposes.isEmpty)
        #expect(inquiry.documentFormats.isEmpty)
        #expect(inquiry.sourceAccounts.isEmpty)
        #expect(inquiry.currencies.isEmpty)
        #expect(inquiry.languages.isEmpty)
    }
}
