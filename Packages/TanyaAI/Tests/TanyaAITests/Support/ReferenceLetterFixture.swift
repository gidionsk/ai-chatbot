//
//  ReferenceLetterFixture.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import DesignKit
import Foundation

@testable import TanyaAI

enum ReferenceLetterFixture {
    static let inquiry = ReferenceLetterInquiry(
        introduction: "Introduction",
        purposes: [OptionItem(id: "001", title: "VISA")],
        documentFormats: [
            OptionItem(id: "SOFTCOPY", title: "Softcopy"), OptionItem(id: "HARDCOPY", title: "Hardcopy")
        ],
        sourceAccounts: [OptionItem(id: "a", title: "Account A", subtitle: "IDR 1.000.000")],
        currencies: [OptionItem(id: "001", title: "IDR")],
        languages: [OptionItem(id: "IN", title: "INDONESIA")],
        address: "Address from inquiry",
        decryptedEmail: "plain@example.com",
        encryptedEmail: "ciphertext-email",
        onlineSessionID: "session-id"
    )

    static var draft: ReferenceLetterDraft {
        var draft = ReferenceLetterDraft(inquiry: inquiry)
        draft.destination = "Embassy"
        draft.accountCodes = ["a"]
        draft.currencyCode = "001"
        draft.languageCode = "IN"
        return draft
    }
}
