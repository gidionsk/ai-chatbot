//
//  ReferenceLetterRequestTests.swift
//  TanyaAITests
//
//  Created by Wendra on 20/11/26.
//

import Testing

@testable import TanyaAI

struct ReferenceLetterRequestTests {
    @Test
    func usesInquiryDefaultsAndRejectsIncompleteDraft() {
        let inquiry = Self.inquiry
        var draft = IntentFormState(rules: ReferenceLetterFieldID.rules(inquiry: inquiry))
        #expect(draft.value(for: .purpose) == .singleSelection("visa"))
        #expect(draft.value(for: .format) == .singleSelection("SOFTCOPY"))
        #expect(draft[text: .email] == inquiry.decryptedEmail)
        #expect(draft.visibleFields.first { $0.id == .email }?.isEnabled == false)
        #expect(draft.value(for: .address) == nil)
        let isValid = draft.validate()
        #expect(!isValid)
        #expect(draft.firstInvalidChoiceID == .accounts)
        #expect(ReferenceLetterRequest(draft: draft, inquiry: inquiry) == nil)
    }

    @Test(arguments: ["SOFTCOPY", "HARDCOPY"])
    func onlySendsDeliveryDataForTheSelectedFormat(format: String) throws {
        let inquiry = Self.inquiry
        var draft = IntentFormState(rules: ReferenceLetterFieldID.rules(inquiry: inquiry))
        draft.select([format], for: .format)
        draft[text: .embassy] = "  Example Embassy  "
        draft.select(["second", "first"], for: .accounts)
        draft.select(["002"], for: .currency)
        draft.select(["IN"], for: .language)
        draft[toggle: .investment] = true

        let isValid = draft.validate()
        #expect(isValid)
        let request = try #require(ReferenceLetterRequest(draft: draft, inquiry: inquiry))
        #expect(request.sourceAccounts == inquiry.sourceAccounts)
        #expect(request.documentFormat.code == format)
        #expect(request.embassy == "Example Embassy")
        #expect(request.currency.code == "002")
        #expect(request.language?.code == "IN")
        #expect(request.isShowBalance && request.isShowInvestmentFund)
        #expect(request.address == (format == "HARDCOPY" ? inquiry.address : nil))
        #expect(request.encryptedEmail == (format == "SOFTCOPY" ? inquiry.encryptedEmail : nil))
        #expect(request.onlineSessionID == inquiry.onlineSessionID)
    }

    @Test
    func changingPurposeResetsTheDependentFields() {
        var draft = IntentFormState(rules: ReferenceLetterFieldID.rules(inquiry: Self.inquiry))
        draft.select(["HARDCOPY"], for: .format)
        draft.select(["first"], for: .accounts)
        draft[text: .embassy] = "Example institution"
        draft[toggle: .balance] = false
        draft.select(["education"], for: .purpose)

        #expect(draft.value(for: .purpose) == .singleSelection("education"))
        #expect(draft.value(for: .format) == .singleSelection("SOFTCOPY"))
        #expect(draft.value(for: .accounts) == .multipleSelection([]))
        #expect(draft[text: .embassy].isEmpty)
        #expect(draft[toggle: .balance])
        #expect(draft.value(for: .address) == nil)
        #expect(draft[text: .email] == Self.inquiry.decryptedEmail)
    }

    @Test(arguments: [false, true])
    @MainActor
    func deliveryAndLanguageFollowInquiry(isLanguageAvailable: Bool) {
        let inquiry = ReferenceLetterServiceDouble.makeInquiry(isLanguageAvailable: isLanguageAvailable)
        var draft = IntentFormState(rules: ReferenceLetterFieldID.rules(inquiry: inquiry))
        #expect(draft.visibleFields.first { $0.id == .email }?.isEnabled == false)
        #expect((draft.value(for: .language) != nil) == isLanguageAvailable)
        draft.select(["HARDCOPY"], for: .format)
        #expect(draft.value(for: .email) == nil)
        #expect(draft[text: .address] == inquiry.address)
        #expect(draft.visibleFields.first { $0.id == .address }?.isEnabled == false)
    }
}

private extension ReferenceLetterRequestTests {
    static var inquiry: ReferenceLetterInquiry {
        ReferenceLetterInquiry(
            introduction: "Example",
            purposes: [FormOption(code: "visa", title: "Visa"), FormOption(code: "education", title: "Education")],
            documentFormats: [
                FormOption(code: "SOFTCOPY", title: "Softcopy"),
                FormOption(code: "HARDCOPY", title: "Hardcopy")
            ],
            sourceAccounts: [FormOption(code: "first", title: "First"), FormOption(code: "second", title: "Second")],
            currencies: [FormOption(code: "002", title: "USD")],
            languages: [FormOption(code: "IN", title: "Indonesia")],
            address: "Example address",
            decryptedEmail: "example@example.com",
            encryptedEmail: "encrypted-email",
            onlineSessionID: "example-session"
        )
    }
}
