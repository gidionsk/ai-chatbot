//
//  ReferenceLetterAdapterFixture.swift
//  TanyaAISandboxTests
//
//  Created by Wendra on 17/11/26.
//

import Foundation
import TanyaAI
import Testing

@testable import Tanya_AI_Sandbox

@MainActor
final class ReferenceLetterAdapterFixture {
    var calls: [ReferenceLetterEndpoint] = []
    var decryptCalls: [String] = []

    func inquiryAdapter() -> ReferenceLetterServiceAdapter {
        ReferenceLetterServiceAdapter(
            fallbackMessage: "Fallback",
            send: { endpoint, _ in
                self.calls.append(endpoint)
                return Data(Self.inquiry.utf8)
            },
            decryptEmail: {
                self.decryptCalls.append($0)
                return "plain@example.com"
            }
        )
    }

    private static let inquiry = #"""
        {"response_code":"00000","data":{
            "introduction":"Introduction",
            "purposes":[{"code":"001","value":"VISA"}],
            "documentFormats":[{"code":"SOFTCOPY","value":"Softcopy"}],
            "sourceAccounts":[{"code":"a","value":"Account A","description":"IDR 1.000.000"}],
            "currencies":[{"code":"001","value":"IDR"}],
            "languages":[{"code":"IN","value":"INDONESIA"}],
            "address":"Address", "email":"ciphertext-email", "onlineSessionId":"session-id"
        }}
        """#
}
