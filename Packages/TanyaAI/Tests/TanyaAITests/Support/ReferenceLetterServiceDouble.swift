//
//  ReferenceLetterServiceDouble.swift
//  TanyaAITests
//
//  Created by Wendra on 22/11/26.
//

import Foundation

@testable import TanyaAI

@MainActor
final class ReferenceLetterServiceDouble: ReferenceLetterService {
    static let receipt = ReferenceLetterReceipt(title: "Receipt", message: "**Accepted**", successID: "ref-1")

    var inquiryResult: Result<ReferenceLetterInquiry, Error> = .success(makeInquiry())
    var submitResult: Result<ReferenceLetterReceipt, Error> = .success(receipt)
    var beforeSubmit: (() async -> Void)?
    private(set) var inquiryCount = 0
    private(set) var submitCount = 0
    private(set) var displayedErrors: [Error] = []

    func inquiry() async throws -> ReferenceLetterInquiry {
        inquiryCount += 1
        return try inquiryResult.get()
    }

    func submit(_ request: ReferenceLetterRequest, pin: String) async throws -> ReferenceLetterReceipt {
        submitCount += 1
        await beforeSubmit?()
        return try submitResult.get()
    }

    func presentAcknowledgementError(_ error: Error) {
        displayedErrors.append(error)
    }

    static func makeInquiry(isLanguageAvailable: Bool = true) -> ReferenceLetterInquiry {
        ReferenceLetterInquiry(
            introduction: "**Introduction**",
            purposes: [FormOption(code: "visa", title: "Visa")],
            documentFormats: [
                FormOption(code: "SOFTCOPY", title: "Softcopy"),
                FormOption(code: "HARDCOPY", title: "Hardcopy")
            ],
            sourceAccounts: [
                FormOption(code: "account", title: "Account"),
                FormOption(
                    code: "long-account",
                    title: "Example joint savings account with a longer display name that wraps into several lines"
                )
            ],
            currencies: [FormOption(code: "002", title: "USD")],
            languages: isLanguageAvailable ? [FormOption(code: "IN", title: "Indonesia")] : [],
            address: "Example address",
            decryptedEmail: "example@example.com",
            encryptedEmail: "encrypted-email",
            onlineSessionID: "example-session"
        )
    }

    static func fill(_ form: ReferenceLetterForm) {
        form.draft[text: .embassy] = "Example Embassy"
        form.draft.select(["account"], for: .accounts)
        form.draft.select(["002"], for: .currency)
        form.draft.select(["IN"], for: .language)
    }
}
