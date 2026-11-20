//
//  MockLetterFormRules.swift
//  TanyaAITests
//
//  Created by Wendra on 19/11/26.
//

@testable import TanyaAI

/// Tiruan aturan untuk pengujian mesin; bukan definisi bisnis Surat Referensi atau kontrak BE.
enum MockLetterFormRules {
    static var rules: IntentFormRules<MockLetterFieldID> {
        IntentFormRules(fields: fields, fieldsToReset: fieldsToReset)
    }

    static func fields(_ values: [MockLetterFieldID: FormFieldValue]) -> [FormField<MockLetterFieldID>] {
        let fields = commonFields
        switch values[.format] {
        case .singleSelection("hardcopy"):
            return fields + [FormField(id: .address, initialValue: .text("Stored address"), isRequired: true)]
        case .singleSelection("softcopy"):
            return fields + [FormField(id: .email, initialValue: .text("stored@example.test"), isEnabled: false)]
        default:
            return fields
        }
    }

    static func fieldsToReset(_ changed: MockLetterFieldID) -> [MockLetterFieldID] {
        switch changed {
        case .purpose:
            return [.format, .embassy, .accounts, .currency, .balance]
        case .format:
            return [.address, .email]
        default:
            return []
        }
    }
}

// MARK: - Helpers

private extension MockLetterFormRules {
    static var commonFields: [FormField<MockLetterFieldID>] {
        [
            FormField(
                id: .purpose,
                initialValue: .singleSelection("visa"),
                options: [FormOption(code: "visa", title: "Visa"), FormOption(code: "other", title: "Other")],
                isRequired: true
            ),
            FormField(
                id: .format,
                initialValue: .singleSelection("softcopy"),
                options: [
                    FormOption(code: "softcopy", title: "Softcopy"),
                    FormOption(code: "hardcopy", title: "Hardcopy")
                ],
                isRequired: true
            ),
            FormField(id: .embassy, initialValue: .text(String()), isRequired: true),
            FormField(
                id: .accounts,
                initialValue: .multipleSelection([]),
                options: [FormOption(code: "main", title: "Main"), FormOption(code: "other", title: "Other")],
                isRequired: true
            ),
            FormField(
                id: .currency,
                initialValue: .singleSelection("idr"),
                options: [FormOption(code: "idr", title: "IDR"), FormOption(code: "usd", title: "USD")]
            ),
            FormField(id: .balance, initialValue: .toggle(false))
        ]
    }
}
