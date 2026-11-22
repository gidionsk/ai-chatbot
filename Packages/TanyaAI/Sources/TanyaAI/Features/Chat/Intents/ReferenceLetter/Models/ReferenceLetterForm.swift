//
//  ReferenceLetterForm.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

import Combine
import Foundation

/// Draft milik satu pesan. Ketikan hanya diamati oleh baris form yang bersangkutan.
@MainActor
final class ReferenceLetterForm: ObservableObject {
    @Published var draft = IntentFormState<ReferenceLetterFieldID>(
        rules: IntentFormRules(fields: { _ in [] }, fieldsToReset: { _ in [] })
    )
    @Published private(set) var inquiry: ReferenceLetterInquiry?
    @Published private(set) var receipt: ReferenceLetterReceipt?
    @Published private(set) var isCancelled = false
    @Published private(set) var isInquiryFailed = false
    @Published private(set) var submissionError: String?
    @Published private(set) var isSubmissionFailed = false
    private var isLoading = false
    private let service: any ReferenceLetterService

    init(service: any ReferenceLetterService) {
        self.service = service
    }

    func load() async {
        guard !isLoading, inquiry == nil else { return }
        isLoading = true
        isInquiryFailed = false
        defer { isLoading = false }
        do {
            let data = try await service.inquiry()
            guard !Task.isCancelled else { return }
            draft = IntentFormState(rules: ReferenceLetterFieldID.rules(inquiry: data))
            inquiry = data
        } catch {
            isInquiryFailed = !Task.isCancelled
        }
    }

    func cancel() {
        isCancelled = true
        discardInquiry()
    }

    func clearSubmissionError() {
        guard isSubmissionFailed else { return }
        isSubmissionFailed = false
        submissionError = nil
    }

    func submit(pin: String) async -> ReferenceLetterReceipt? {
        guard pin.count == ChatWire.referenceLetterPinLength, !isCancelled, receipt == nil, let inquiry,
            draft.validate(),
            let request = ReferenceLetterRequest(draft: draft, inquiry: inquiry)
        else { return nil }
        clearSubmissionError()
        do {
            let result = try await service.submit(request, pin: pin)
            receipt = result
            discardInquiry()
            return result
        } catch {
            // Hanya pesan yang sengaja dipetakan host untuk ditampilkan yang diteruskan ke UI.
            submissionError = (error as? LocalizedError)?.errorDescription
            isSubmissionFailed = true
            return nil
        }
    }
}

private extension ReferenceLetterForm {
    func discardInquiry() {
        inquiry = nil
        draft = IntentFormState(rules: IntentFormRules(fields: { _ in [] }, fieldsToReset: { _ in [] }))
    }
}

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
            FormField(id: .investment, initialValue: .toggle(false))
        ]
        if !inquiry.languages.isEmpty { fields.append(choice(.language, options: inquiry.languages)) }
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

/// Cara pengiriman yang dikenali form berdasarkan kode inquiry.
enum ReferenceLetterDocumentFormat: String {
    case softcopy
    case hardcopy

    init?(code: String) {
        self.init(rawValue: code.lowercased())
    }
}
