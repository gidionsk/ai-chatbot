//
//  ReferenceLetterACKRequest.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 16/11/26.
//

import TanyaAI

/// Mapping snapshot SDK ke kontrak ACK milik BE, termasuk token hasil verifikasi host.
struct ReferenceLetterACKRequest: Encodable {
    struct Choice: Encodable {
        let code: String
        let value: String
        let description: String?

        init(_ choice: ReferenceLetterRequest.Choice) {
            code = choice.code
            value = choice.value
            description = choice.description
        }
    }

    let purpose: Choice
    let documentFormat: Choice
    let embassy: String
    let sourceAccounts: [Choice]
    let currency: Choice
    let isShowBalance: Bool
    let isShowInvestmentFund: Bool
    let address: String
    let email: String
    let language: Choice
    let onlineSessionId: String
    let responseCodeOTP: String

    init(_ snapshot: ReferenceLetterRequest, verification: ReferenceLetterVerification) {
        purpose = Choice(snapshot.purpose)
        documentFormat = Choice(snapshot.documentFormat)
        embassy = snapshot.embassy
        sourceAccounts = snapshot.sourceAccounts.map(Choice.init)
        currency = Choice(snapshot.currency)
        isShowBalance = snapshot.isShowBalance
        isShowInvestmentFund = snapshot.isShowInvestmentFund
        address = snapshot.address
        email = snapshot.email
        language = Choice(snapshot.language)
        onlineSessionId = snapshot.onlineSessionId
        responseCodeOTP = verification.responseCodeOTP
    }
}
