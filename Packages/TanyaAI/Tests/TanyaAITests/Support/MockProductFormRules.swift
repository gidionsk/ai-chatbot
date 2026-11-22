//
//  MockProductFormRules.swift
//  TanyaAITests
//
//  Created by Wendra on 19/11/26.
//

@testable import TanyaAI

/// Tiruan kedua: opsi dan urutan berubah mengikuti kategori; teks wajib hanya saat toggle menyala.
enum MockProductFormRules {
    static var rules: IntentFormRules<MockProductFieldID> {
        IntentFormRules(fields: fields, fieldsToReset: { $0 == .category ? [.product] : [] })
    }

    static func fields(_ values: [MockProductFieldID: FormFieldValue]) -> [FormField<MockProductFieldID>] {
        let isDeposit = values[.category] == .singleSelection("deposit")
        let category = FormField<MockProductFieldID>(
            id: .category,
            initialValue: .singleSelection("fund"),
            options: [FormOption(code: "fund", title: "Fund"), FormOption(code: "deposit", title: "Deposit")],
            isRequired: true
        )
        let product = FormField<MockProductFieldID>(
            id: .product,
            initialValue: .singleSelection(nil),
            options: productOptions(isDeposit: isDeposit),
            isRequired: true
        )
        let account = FormField<MockProductFieldID>(
            id: .fundingAccount,
            initialValue: .multipleSelection([]),
            options: [FormOption(code: "checking", title: "Checking"), FormOption(code: "savings", title: "Savings")],
            isRequired: true
        )
        let details = [
            FormField<MockProductFieldID>(id: .needsDetails, initialValue: .toggle(false)),
            FormField(
                id: .details,
                initialValue: .text(String()),
                isRequired: values[.needsDetails] == .toggle(true)
            )
        ]
        if isDeposit { return [category, account, product] + details }
        return [category, product, account] + details
    }
}

// MARK: - Helpers

private extension MockProductFormRules {
    static func productOptions(isDeposit: Bool) -> [FormOption] {
        let shared = FormOption(code: "shared", title: "Shared choice")
        if isDeposit { return [shared, FormOption(code: "fixed", title: "Fixed deposit")] }
        return [shared, FormOption(code: "equity", title: "Equity fund")]
    }
}
