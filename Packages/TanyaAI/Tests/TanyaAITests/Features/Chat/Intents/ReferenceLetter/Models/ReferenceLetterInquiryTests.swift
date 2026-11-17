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
    func inquiryPreservesHostChoiceOrderAndAccountDetails() {
        let purposes = [FormOption(code: "purpose-b", title: "Second"), FormOption(code: "purpose-a", title: "First")]
        let accounts = [FormOption(code: "account-a", title: "Sample account - 1234", subtitle: "Sample balance")]
        let formats = [FormOption(code: "format-a", title: "Sample format")]
        let currencies = [FormOption(code: "currency-a", title: "Sample currency")]
        let languages = [FormOption(code: "language-a", title: "Sample language")]
        let inquiry = ReferenceLetterInquiry(
            introduction: "Sample introduction",
            purposes: purposes,
            documentFormats: formats,
            sourceAccounts: accounts,
            currencies: currencies,
            languages: languages,
            address: "Sample address",
            decryptedEmail: "sample@example.com",
            encryptedEmail: "opaque-host-value",
            onlineSessionID: "sample-session"
        )
        #expect(inquiry.introduction == "Sample introduction")
        #expect(inquiry.purposes == purposes)
        #expect(inquiry.documentFormats == formats)
        #expect(inquiry.sourceAccounts == accounts)
        #expect(inquiry.currencies == currencies)
        #expect(inquiry.languages == languages)
        #expect(inquiry.address == "Sample address")
        #expect(inquiry.decryptedEmail == "sample@example.com")
        #expect(inquiry.encryptedEmail == "opaque-host-value")
        #expect(inquiry.onlineSessionID == "sample-session")
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
