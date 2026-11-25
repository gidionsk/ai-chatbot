//
//  ReferenceLetterFieldID.swift
//  TanyaAI
//
//  Created by Wendra on 22/11/26.
//

/// Field, urutan, dan aturan reset pada form Surat Referensi.
enum ReferenceLetterFieldID: String, CaseIterable {
    case purpose
    case format
    case embassy
    case accounts
    case currency
    case balance
    case investment
    case language
    case email
    case address

    static func rules(inquiry: ReferenceLetterInquiry) -> IntentFormRules<Self> {
        IntentFormRules(
            fields: { values in fields(inquiry: inquiry, format: values[.format]) },
            fieldsToReset: { $0 == .purpose ? Self.allCases.filter { $0 != .purpose } : [] }
        )
    }

    var label: ChatCopy {
        switch self {
        case .purpose: return .referenceLetterPurpose
        case .format: return .referenceLetterFormat
        case .embassy: return .referenceLetterEmbassy
        case .accounts: return .referenceLetterAccounts
        case .currency: return .referenceLetterCurrency
        case .balance: return .referenceLetterBalance
        case .investment: return .referenceLetterInvestment
        case .language: return .referenceLetterLanguage
        case .email: return .referenceLetterEmail
        case .address: return .referenceLetterAddress
        }
    }
}

private extension ReferenceLetterFieldID {
    static func fields(inquiry: ReferenceLetterInquiry, format: FormFieldValue?) -> [FormField<Self>] {
        let formats = inquiry.documentFormats.filter { ReferenceLetterDocumentFormat(code: $0.code) != nil }
        var fields: [FormField<Self>] = [
            choice(.purpose, options: inquiry.purposes, isFirstSelected: true),
            choice(.format, options: formats, isFirstSelected: true),
            FormField(id: .embassy, initialValue: .text(String()), isRequired: true),
            FormField(
                id: .accounts,
                initialValue: .multipleSelection([]),
                options: inquiry.sourceAccounts,
                isRequired: true
            ),
            choice(.currency, options: inquiry.currencies),
            FormField(id: .balance, initialValue: .toggle(true)),
            FormField(id: .investment, initialValue: .toggle(false)),
            choice(.language, options: inquiry.languages)
        ]
        if case .singleSelection(let code?) = format, ReferenceLetterDocumentFormat(code: code) == .softcopy {
            fields.append(FormField(id: .email, initialValue: .text(inquiry.decryptedEmail), isEnabled: false))
        }
        if case .singleSelection(let code?) = format, ReferenceLetterDocumentFormat(code: code) == .hardcopy {
            fields.append(FormField(id: .address, initialValue: .text(inquiry.address), isEnabled: false))
        }
        return fields
    }

    static func choice(_ id: Self, options: [FormOption], isFirstSelected: Bool = false) -> FormField<Self> {
        let initialCode = isFirstSelected ? options.first(where: { !$0.code.isEmpty })?.code : nil
        return FormField(id: id, initialValue: .singleSelection(initialCode), options: options, isRequired: true)
    }
}
