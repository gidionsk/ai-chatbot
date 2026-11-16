//
//  ReferenceLetterInquirySessionTests.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

import Testing

@testable import TanyaAI

@MainActor
struct ReferenceLetterInquirySessionTests {
    @Test
    func inquiryOnlyHostCanLoadAndEditTheForm() async {
        let service = ReferenceLetterInquirySpy()
        let session = ReferenceLetterSession(service: service)
        await session.load()
        session.draft.destination = "Embassy"
        #expect(session.phase == .editing)
        #expect(session.draft.purposeCode == "001")
        #expect(session.draft.destination == "Embassy")
        #expect(service.inquiryCount == 1)
    }

    @Test
    func historyDoesNotLoadInquiry() async {
        let service = ReferenceLetterInquirySpy()
        let session = ReferenceLetterSession(service: service, isHistory: true)
        await session.load()
        #expect(service.inquiryCount == 0)
        #expect(session.phase == .history)
    }
}
