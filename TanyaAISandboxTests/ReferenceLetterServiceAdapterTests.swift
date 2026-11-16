//
//  ReferenceLetterServiceAdapterTests.swift
//  TanyaAISandboxTests
//
//  Created by Wendra on 16/11/26.
//

import Foundation
import Testing

@testable import Tanya_AI_Sandbox

@MainActor
struct ReferenceLetterServiceAdapterTests {
    @Test
    func mapsInquiryAndSeparatesDisplayEmailFromCiphertext() async throws {
        let fixture = ReferenceLetterAdapterFixture()
        let inquiry = try await fixture.inquiryAdapter().inquiry()
        #expect(inquiry.purposes.first?.id == "001")
        #expect(inquiry.sourceAccounts.first?.subtitle == "IDR 1.000.000")
        #expect(inquiry.decryptedEmail == "plain@example.com")
        #expect(inquiry.encryptedEmail == "ciphertext-email")
        #expect(fixture.decryptCalls == ["ciphertext-email"])
        #expect(fixture.calls == [.inquiry])
        #expect(ReferenceLetterEndpoint.inquiry.method == "GET")
    }

    @Test
    func businessErrorDoesNotExposeFormData() async {
        let adapter = ReferenceLetterServiceAdapter(
            fallbackMessage: "Fallback",
            send: { _, _ in Data(#"{"response_code":"99999","responseDescription":"Unavailable"}"#.utf8) },
            decryptEmail: { $0 }
        )
        do {
            _ = try await adapter.inquiry()
            Issue.record("Inquiry business error must fail")
        } catch {}
    }
}
