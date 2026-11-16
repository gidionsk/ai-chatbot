//
//  ReferenceLetterSessionTests.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

@MainActor
struct ReferenceLetterSessionTests {
    @Test
    func invalidFormStaysEditableAndDoesNotVerify() async {
        let service = ReferenceLetterServiceSpy()
        let session = ReferenceLetterSession(service: service)
        await session.load()
        #expect(!session.confirm())
        #expect(session.phase == .editing)
        #expect(session.invalidFields.contains(.accounts))
        #expect(session.invalidFields.contains(.destination))
        #expect(service.calls == ["inquiry"])
    }

    @Test
    func invalidPINCannotReachACKAndCanBeRetried() async {
        let (session, service) = await readySession()
        service.verificationError = ReferenceLetterServiceError.invalidPIN("PIN salah")
        #expect(session.confirm())
        await session.submit(pin: "123456")
        #expect(session.phase == .awaitingPIN)
        #expect(session.errorMessage == "PIN salah")
        #expect(service.calls == ["inquiry", "verify"])
        service.verificationError = nil
        await session.submit(pin: "654321")
        #expect(service.calls == ["inquiry", "verify", "verify", "ack"])
        #expect(session.phase == .completed)
        #expect(session.receipt?.message == "Exact ACK message")
    }

    @Test
    func blockedPINLocksTheFlow() async {
        let (session, service) = await readySession()
        service.verificationError = ReferenceLetterServiceError.blockedPIN("PIN diblokir")
        #expect(session.confirm())
        await session.submit(pin: "123456")
        await session.submit(pin: "123456")
        #expect(session.phase == .blocked)
        #expect(service.calls == ["inquiry", "verify"])
    }

    @Test
    func doubleSubmitUsesOneVerificationAndAnImmutableSnapshot() async {
        let (session, service) = await readySession()
        service.isHoldingVerification = true
        #expect(session.confirm())
        let task = Task { await session.submit(pin: "123456") }
        await waitUntil { service.continuation != nil }
        session.draft.destination = "Changed after PIN opened"
        await session.submit(pin: "654321")
        #expect(service.calls == ["inquiry", "verify"])
        service.releaseVerification()
        await task.value
        #expect(service.receivedRequest?.embassy == "Embassy")
        #expect(service.receivedRequest?.email == "ciphertext-email")
        #expect(service.receivedVerification?.responseCodeOTP == "verified-response-otp")
        #expect(service.calls == ["inquiry", "verify", "ack"])
    }

    @Test
    func staleVerificationCannotSubmitAfterConversationChanges() async {
        let (session, service) = await readySession()
        service.isHoldingVerification = true
        #expect(session.confirm())
        let task = Task { await session.submit(pin: "123456") }
        await waitUntil { service.continuation != nil }
        session.invalidate()
        service.releaseVerification()
        await task.value
        #expect(service.calls == ["inquiry", "verify"])
        #expect(session.phase == .cancelled)
    }

    @Test
    func ACKTimeoutDoesNotResubmitAnUncertainTransaction() async {
        let (session, service) = await readySession()
        service.acknowledgementError = URLError(.timedOut)
        #expect(session.confirm())
        await session.submit(pin: "123456")
        #expect(session.phase == .uncertain)
        #expect(session.receipt == nil)
        #expect(!session.confirm())
        await session.submit(pin: "123456")
        #expect(service.calls == ["inquiry", "verify", "ack"])
    }

    @Test
    func historyNeverCallsTransactionServices() async {
        let service = ReferenceLetterServiceSpy()
        let session = ReferenceLetterSession(service: service, isHistory: true)
        await session.load()
        #expect(!session.confirm())
        await session.submit(pin: "123456")
        #expect(service.calls.isEmpty)
        #expect(session.phase == .history)
    }

    @Test
    func leavingThePageBeforeVerificationFinishesPreventsACK() async {
        let (session, service) = await readySession()
        service.isHoldingVerification = true
        #expect(session.confirm())
        let task = Task { await session.submit(pin: "123456") }
        await waitUntil { service.continuation != nil }
        session.leaveScreen()
        service.releaseVerification()
        await task.value
        #expect(session.phase == .cancelled)
        #expect(service.calls == ["inquiry", "verify"])
    }

    @Test
    func leavingDuringACKDoesNotClaimTheRequestWasCancelled() async {
        let (session, service) = await readySession()
        service.isHoldingACK = true
        #expect(session.confirm())
        let task = Task { await session.submit(pin: "123456") }
        await waitUntil { service.ackContinuation != nil }
        session.leaveScreen()
        service.releaseACK()
        await task.value
        #expect(session.phase == .uncertain)
        #expect(session.receipt == nil)
        #expect(!session.confirm())
        #expect(service.calls == ["inquiry", "verify", "ack"])
    }

    @Test(arguments: ["12345", "１２３４５６", "1234567", "abc123"])
    func malformedPINIsNotSent(pin: String) async {
        let (session, service) = await readySession()
        #expect(session.confirm())
        await session.submit(pin: pin)
        #expect(service.calls == ["inquiry"])
    }
}

// MARK: - Helpers

private extension ReferenceLetterSessionTests {
    func readySession() async -> (ReferenceLetterSession, ReferenceLetterServiceSpy) {
        let service = ReferenceLetterServiceSpy()
        let session = ReferenceLetterSession(service: service)
        await session.load()
        session.draft = ReferenceLetterFixture.draft
        return (session, service)
    }
}
