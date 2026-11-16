//
//  ReferenceLetterServiceSpy.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import Foundation

@testable import TanyaAI

@MainActor
final class ReferenceLetterServiceSpy: ReferenceLetterService {
    var calls: [String] = []
    var verificationError: Error?
    var acknowledgementError: Error?
    var isHoldingVerification = false
    var isHoldingACK = false
    var continuation: CheckedContinuation<ReferenceLetterVerification, Error>?
    var ackContinuation: CheckedContinuation<ReferenceLetterReceipt, Error>?
    var receivedRequest: ReferenceLetterRequest?

    func inquiry() async throws -> ReferenceLetterInquiry {
        calls.append("inquiry")
        return ReferenceLetterFixture.inquiry
    }

    func verify(pin: String) async throws -> ReferenceLetterVerification {
        calls.append("verify")
        if let verificationError { throw verificationError }
        if isHoldingVerification {
            return try await withCheckedThrowingContinuation { continuation = $0 }
        }
        return ReferenceLetterVerification(responseCodeOTP: "verified-response-otp")
    }

    func acknowledge(_ request: ReferenceLetterRequest) async throws -> ReferenceLetterReceipt {
        calls.append("ack")
        receivedRequest = request
        if let acknowledgementError { throw acknowledgementError }
        if isHoldingACK {
            return try await withCheckedThrowingContinuation { ackContinuation = $0 }
        }
        return ReferenceLetterReceipt(title: "", message: "Exact ACK message")
    }

    func releaseVerification() {
        continuation?.resume(returning: ReferenceLetterVerification(responseCodeOTP: "verified-response-otp"))
        continuation = nil
    }

    func releaseACK() {
        ackContinuation?.resume(returning: ReferenceLetterReceipt(title: "", message: "Exact ACK message"))
        ackContinuation = nil
    }
}
