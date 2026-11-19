//
//  ReferenceLetterDemoData+Fields.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

extension ReferenceLetterDemoData {
    static var fields: [FormField<ReferenceLetterDemoField>] {
        headerFields + accountFields + preferenceFields + deliveryFields
    }
}

// MARK: - Helpers

private extension ReferenceLetterDemoData {
    static var headerFields: [FormField<ReferenceLetterDemoField>] {
        [
            FormField(
                id: .purpose,
                initialValue: .singleSelection(inquiry.purposes.first?.code),
                options: inquiry.purposes,
                isRequired: true
            ),
            FormField(
                id: .format,
                initialValue: .singleSelection(inquiry.documentFormats.first?.code),
                options: inquiry.documentFormats,
                isRequired: true
            ),
            FormField(id: .embassy, initialValue: .text(initialEmbassy), isRequired: true)
        ]
    }

    static var accountFields: [FormField<ReferenceLetterDemoField>] {
        [
            FormField(
                id: .accounts,
                initialValue: .multipleSelection(inquiry.sourceAccounts.first.map { [$0.code] } ?? []),
                options: inquiry.sourceAccounts,
                isRequired: true
            ),
            FormField(
                id: .currency,
                initialValue: .singleSelection(inquiry.currencies.first?.code),
                options: inquiry.currencies,
                isRequired: true
            )
        ]
    }

    static var preferenceFields: [FormField<ReferenceLetterDemoField>] {
        [
            FormField(id: .balance, initialValue: .toggle(true)),
            FormField(id: .investment, initialValue: .toggle(false))
        ]
    }

    static var deliveryFields: [FormField<ReferenceLetterDemoField>] {
        [
            FormField(
                id: .email,
                initialValue: .text(inquiry.decryptedEmail),
                isEnabled: false,
                condition: FormFieldCondition(fieldID: .format, value: .singleSelection("SOFTCOPY"))
            ),
            FormField(
                id: .address,
                initialValue: .text(inquiry.address),
                isEnabled: false,
                condition: FormFieldCondition(fieldID: .format, value: .singleSelection("HARDCOPY"))
            )
        ]
    }
}
