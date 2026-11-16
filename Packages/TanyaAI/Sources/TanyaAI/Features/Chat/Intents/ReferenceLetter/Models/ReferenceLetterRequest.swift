//
//  ReferenceLetterRequest.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import DesignKit

/// Body POST /user/tanya-ai/reference-letter/ack. Label dan description disalin persis dari inquiry BE.
public struct ReferenceLetterRequest: Encodable, Equatable {
    public struct Choice: Encodable, Equatable {
        public let code: String
        public let value: String
        public let description: String?

        init(_ option: OptionItem) {
            code = option.id
            value = option.title
            description = option.subtitle
        }
    }

    public let purpose: Choice
    public let documentFormat: Choice
    public let embassy: String
    public let sourceAccounts: [Choice]
    public let currency: Choice
    public let isShowBalance: Bool
    public let isShowInvestmentFund: Bool
    public let address: String
    public let email: String
    public let language: Choice
    public let onlineSessionId: String
    public private(set) var responseCodeOTP = String()

    /// Snapshot immutable sebelum PIN dibuka. Tidak membuat label atau rekening yang tidak berasal dari inquiry.
    public init?(inquiry: ReferenceLetterInquiry, draft: ReferenceLetterDraft) {
        guard !inquiry.onlineSessionID.isEmpty, draft.invalidFields(in: inquiry).isEmpty,
            let purpose = inquiry.purposes.first(where: { $0.id == draft.purposeCode }),
            let format = inquiry.documentFormats.first(where: { $0.id == draft.documentFormatCode }),
            let currency = inquiry.currencies.first(where: { $0.id == draft.currencyCode }),
            let language = inquiry.languages.first(where: { $0.id == draft.languageCode })
        else { return nil }
        self.purpose = Choice(purpose)
        documentFormat = Choice(format)
        embassy = draft.destination
        let codes = Set(draft.accountCodes)
        sourceAccounts = inquiry.sourceAccounts.filter { codes.contains($0.id) }.map(Choice.init)
        self.currency = Choice(currency)
        isShowBalance = draft.isBalanceShown
        isShowInvestmentFund = draft.isInvestmentShown
        address = inquiry.address
        email = inquiry.encryptedEmail
        self.language = Choice(language)
        onlineSessionId = inquiry.onlineSessionID
    }

    func authorized(with verification: ReferenceLetterVerification) -> Self {
        var request = self
        request.responseCodeOTP = verification.responseCodeOTP
        return request
    }
}
