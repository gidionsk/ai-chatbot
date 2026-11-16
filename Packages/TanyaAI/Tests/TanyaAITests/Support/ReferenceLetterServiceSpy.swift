//
//  ReferenceLetterServiceSpy.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import Foundation

@testable import TanyaAI

@MainActor
final class ReferenceLetterServiceSpy: ReferenceLetterService, ReferenceLetterSubmissionService {
    var calls: [String] = []
    var authorizationError: Error?
    var acknowledgementError: Error?
    var isAuthorizationCancelled = false
    var isAuthorizationEmpty = false
    var isHoldingAuthorization = false
    var isHoldingACK = false
    var continuation: CheckedContinuation<ReferenceLetterAuthorization?, Error>?
    var ackContinuation: CheckedContinuation<ReferenceLetterReceipt, Error>?
    var receivedRequest: ReferenceLetterRequest?
    var receivedAuthorization: ReferenceLetterAuthorization?

    func inquiry() async throws -> ReferenceLetterInquiry {
        calls.append("inquiry")
        return ReferenceLetterFixture.inquiry
    }

    func authorize() async throws -> ReferenceLetterAuthorization? {
        calls.append("authorize")
        if let authorizationError { throw authorizationError }
        if isAuthorizationCancelled { return nil }
        if isHoldingAuthorization {
            return try await withCheckedThrowingContinuation { continuation = $0 }
        }
        return authorization
    }

    func acknowledge(
        _ request: ReferenceLetterRequest,
        authorization: ReferenceLetterAuthorization
    ) async throws -> ReferenceLetterReceipt {
        calls.append("ack")
        receivedRequest = request
        receivedAuthorization = authorization
        if let acknowledgementError { throw acknowledgementError }
        if isHoldingACK {
            return try await withCheckedThrowingContinuation { ackContinuation = $0 }
        }
        return ReferenceLetterReceipt(title: "", message: "Exact ACK message")
    }

    func releaseAuthorization() {
        continuation?.resume(returning: authorization)
        continuation = nil
    }

    func releaseACK() {
        ackContinuation?.resume(returning: ReferenceLetterReceipt(title: "", message: "Exact ACK message"))
        ackContinuation = nil
    }

    private var authorization: ReferenceLetterAuthorization {
        ReferenceLetterAuthorization(responseCodeOTP: isAuthorizationEmpty ? "" : "existing-host-result")
    }
}
