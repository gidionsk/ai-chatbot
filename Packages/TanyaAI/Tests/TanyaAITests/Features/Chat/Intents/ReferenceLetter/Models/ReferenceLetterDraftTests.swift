//
//  ReferenceLetterDraftTests.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import DesignKit
import Testing

@testable import TanyaAI

struct ReferenceLetterDraftTests {
    @Test
    func defaultsUseTheFirstBackendCodes() {
        let data = inquiry()
        let draft = ReferenceLetterDraft(inquiry: data)
        #expect(draft.purposeCode == "purpose-visa")
        #expect(draft.documentFormatCode == "SOFTCOPY")
        #expect(draft.currencyCode == nil)
        #expect(draft.accountCodes.isEmpty)
        #expect(draft.isBalanceShown)
        #expect(!draft.isInvestmentShown)
    }

    @Test
    func emptyListsDoNotCreateInventedDefaults() {
        let data = inquiry(purposes: [], formats: [])
        let draft = ReferenceLetterDraft(inquiry: data)
        #expect(draft.purposeCode == nil)
        #expect(draft.documentFormatCode == nil)
        #expect(draft.invalidFields(in: data).contains(.purpose))
        #expect(draft.invalidFields(in: data).contains(.documentFormat))
    }

    @Test
    func accountCodesAreUniqueAndFollowBackendOrder() {
        let data = inquiry()
        var draft = ReferenceLetterDraft(inquiry: data)
        draft.select(["b", "missing", "b", "a"], for: .accounts, inquiry: data)
        #expect(draft.accountCodes == ["a", "b"])
        #expect(data.sourceAccounts.first?.subtitle == "IDR 1.000.000")
    }

    @Test
    func savedAccountsCanBeClearedAndThenValidated() {
        let data = inquiry()
        var draft = ReferenceLetterDraft(inquiry: data)
        draft.select(["a"], for: .accounts, inquiry: data)
        draft.select([], for: .accounts, inquiry: data)
        #expect(draft.accountCodes.isEmpty)
        #expect(draft.invalidFields(in: data).contains(.accounts))
    }

    @Test(arguments: ["   ", "\n\t"])
    func whitespaceDestinationIsInvalid(destination: String) {
        let data = inquiry()
        var draft = ReferenceLetterDraft(inquiry: data)
        draft.destination = destination
        #expect(draft.invalidFields(in: data).contains(.destination))
    }

    @Test
    func requestValuesKeepCodesInsteadOfTranslatedLabels() {
        let data = inquiry()
        var draft = ReferenceLetterDraft(inquiry: data)
        draft.destination = "Kedutaan"
        draft.select(["b"], for: .accounts, inquiry: data)
        draft.select(["002"], for: .currency, inquiry: data)
        draft.select(["IN"], for: .language, inquiry: data)
        #expect(draft.currencyCode == "002")
        #expect(draft.invalidFields(in: data).isEmpty)
        draft.documentFormatCode = "unsupported-format"
        #expect(draft.invalidFields(in: data).contains(.documentFormat))
    }

    @Test
    func aRemovedAccountCannotBeSubmitted() {
        let data = inquiry()
        var draft = ReferenceLetterDraft(inquiry: data)
        draft.accountCodes = ["deleted-account"]
        #expect(draft.invalidFields(in: data).contains(.accounts))
    }
}

// MARK: - Helpers

private extension ReferenceLetterDraftTests {
    func inquiry(
        purposes: [OptionItem] = [OptionItem(id: "purpose-visa", title: "Pengajuan VISA")],
        formats: [OptionItem] = [
            OptionItem(id: "SOFTCOPY", title: "Salinan digital"),
            OptionItem(id: "HARDCOPY", title: "Salinan cetak")
        ]
    ) -> ReferenceLetterInquiry {
        ReferenceLetterInquiry(
            introduction: "Lengkapi form",
            purposes: purposes,
            documentFormats: formats,
            sourceAccounts: [
                OptionItem(id: "a", title: "Rekening A", subtitle: "IDR 1.000.000"),
                OptionItem(id: "b", title: "Rekening B")
            ],
            currencies: [OptionItem(id: "002", title: "USD")],
            languages: [OptionItem(id: "IN", title: "INDONESIA")],
            address: "Alamat dari BE",
            decryptedEmail: "sample@example.com",
            encryptedEmail: "encrypted-email",
            onlineSessionID: "fixture-session"
        )
    }
}
