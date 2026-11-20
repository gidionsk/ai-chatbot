//
//  ReferenceLetterRequest.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

import Foundation

/// Nilai yang dipilih nasabah. Host memetakan model ini ke payload ACK miliknya.
public struct ReferenceLetterRequest {
    public let purpose: FormOption
    public let documentFormat: FormOption
    public let embassy: String
    public let sourceAccounts: [FormOption]
    public let currency: FormOption
    public let isShowBalance: Bool
    public let isShowInvestmentFund: Bool
    public let address: String?
    public let encryptedEmail: String?
    public let language: FormOption?
    public let onlineSessionID: String
}

extension ReferenceLetterRequest {
    init?(draft: IntentFormState<ReferenceLetterFieldID>, inquiry: ReferenceLetterInquiry) {
        guard let purpose = draft.selectedOption(for: .purpose),
            let format = draft.selectedOption(for: .format),
            let delivery = ReferenceLetterDocumentFormat(code: format.code),
            let currency = draft.selectedOption(for: .currency)
        else { return nil }
        let accounts = draft.visibleFields.first { $0.id == .accounts }?.options ?? []
        let selectedAccounts = Set(draft.value(for: .accounts)?.selectedCodes ?? [])
        let sourceAccounts = accounts.filter { selectedAccounts.contains($0.code) }
        let language = draft.selectedOption(for: .language)
        guard !sourceAccounts.isEmpty, inquiry.languages.isEmpty || language != nil else { return nil }
        self.init(
            purpose: purpose,
            documentFormat: format,
            embassy: draft[text: .embassy].trimmingCharacters(in: .whitespacesAndNewlines),
            sourceAccounts: sourceAccounts,
            currency: currency,
            isShowBalance: draft[toggle: .balance],
            isShowInvestmentFund: draft[toggle: .investment],
            address: delivery == .hardcopy ? inquiry.address : nil,
            encryptedEmail: delivery == .softcopy ? inquiry.encryptedEmail : nil,
            language: language,
            onlineSessionID: inquiry.onlineSessionID
        )
    }
}

private extension IntentFormState where FieldID == ReferenceLetterFieldID {
    func selectedOption(for id: FieldID) -> FormOption? {
        guard case .singleSelection(let code) = value(for: id) else { return nil }
        return visibleFields.first { $0.id == id }?.options.first { $0.code == code }
    }
}
