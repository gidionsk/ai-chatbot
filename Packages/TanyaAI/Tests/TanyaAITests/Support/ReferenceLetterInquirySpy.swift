//
//  ReferenceLetterInquirySpy.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

@testable import TanyaAI

@MainActor
final class ReferenceLetterInquirySpy: ReferenceLetterService {
    var inquiryCount = Int.zero

    func inquiry() async throws -> ReferenceLetterInquiry {
        inquiryCount += 1
        return ReferenceLetterFixture.inquiry
    }
}
