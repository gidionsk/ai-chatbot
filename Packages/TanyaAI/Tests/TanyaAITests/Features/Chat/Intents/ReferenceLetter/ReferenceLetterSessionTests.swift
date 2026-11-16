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
    func invalidFormDoesNotRequestHostAuthorization() async {
        let service = ReferenceLetterServiceSpy()
        let session = ReferenceLetterSession(service: service, submission: service)
        await session.load()
        await session.submit()
        #expect(session.phase == .editing)
        #expect(session.invalidFields.contains(.accounts))
        #expect(session.invalidFields.contains(.destination))
        #expect(service.calls == ["inquiry"])
    }

    @Test
    func cancellingHostPINReturnsToEditingWithoutACK() async {
        let (session, service) = await readySession()
        service.isAuthorizationCancelled = true
        await session.submit()
        #expect(session.phase == .editing)
        #expect(session.receipt == nil)
        #expect(service.calls == ["inquiry", "authorize"])
    }

    @Test
    func failedHostAuthorizationDoesNotACK() async {
        let (session, service) = await readySession()
        service.authorizationError = ReferenceLetterServiceError.authorization("Host verification failed")
        await session.submit()
        #expect(session.phase == .editing)
        #expect(session.errorMessage == "Host verification failed")
        #expect(service.calls == ["inquiry", "authorize"])
    }

    @Test
    func emptyAuthorizationDoesNotACK() async {
        let (session, service) = await readySession()
        service.isAuthorizationEmpty = true
        await session.submit()
        #expect(session.phase == .editing)
        #expect(session.failure == .authorizationUnavailable)
        #expect(service.calls == ["inquiry", "authorize"])
    }

    @Test
    func doubleSubmitUsesOneHostFlowAndAnImmutableSnapshot() async {
        let (session, service) = await readySession()
        service.isHoldingAuthorization = true
        let task = Task { await session.submit() }
        await waitUntil { service.continuation != nil }
        session.draft.destination = "Changed after host PIN opened"
        await session.submit()
        service.releaseAuthorization()
        await task.value
        #expect(service.receivedRequest?.embassy == "Embassy")
        #expect(service.receivedRequest?.email == "ciphertext-email")
        #expect(service.receivedAuthorization?.responseCodeOTP == "existing-host-result")
        #expect(service.calls == ["inquiry", "authorize", "ack"])
        #expect(session.phase == .completed)
        #expect(session.receipt?.message == "Exact ACK message")
    }

    @Test
    func staleHostAuthorizationCannotSubmitAfterConversationChanges() async {
        let (session, service) = await readySession()
        service.isHoldingAuthorization = true
        let task = Task { await session.submit() }
        await waitUntil { service.continuation != nil }
        session.invalidate()
        service.releaseAuthorization()
        await task.value
        #expect(service.calls == ["inquiry", "authorize"])
        #expect(session.phase == .cancelled)
    }

    @Test
    func ACKTimeoutDoesNotResubmitAnUncertainTransaction() async {
        let (session, service) = await readySession()
        service.acknowledgementError = URLError(.timedOut)
        await session.submit()
        #expect(session.phase == .uncertain)
        #expect(session.receipt == nil)
        await session.submit()
        #expect(service.calls == ["inquiry", "authorize", "ack"])
    }

    @Test
    func explicitACKRejectionAllowsEditing() async {
        let (session, service) = await readySession()
        service.acknowledgementError = ReferenceLetterServiceError.rejected("Request rejected")
        await session.submit()
        #expect(session.phase == .editing)
        #expect(session.errorMessage == "Request rejected")
    }

    @Test
    func leavingThePageBeforeHostAuthorizationFinishesPreventsACK() async {
        let (session, service) = await readySession()
        service.isHoldingAuthorization = true
        let task = Task { await session.submit() }
        await waitUntil { service.continuation != nil }
        session.leaveScreen()
        service.releaseAuthorization()
        await task.value
        #expect(session.phase == .cancelled)
        #expect(service.calls == ["inquiry", "authorize"])
    }

    @Test
    func leavingDuringACKDoesNotClaimTheRequestWasCancelled() async {
        let (session, service) = await readySession()
        service.isHoldingACK = true
        let task = Task { await session.submit() }
        await waitUntil { service.ackContinuation != nil }
        session.leaveScreen()
        service.releaseACK()
        await task.value
        #expect(session.phase == .uncertain)
        #expect(session.receipt == nil)
        #expect(service.calls == ["inquiry", "authorize", "ack"])
    }
}

// MARK: - Helpers

private extension ReferenceLetterSessionTests {
    func readySession() async -> (ReferenceLetterSession, ReferenceLetterServiceSpy) {
        let service = ReferenceLetterServiceSpy()
        let session = ReferenceLetterSession(service: service, submission: service)
        await session.load()
        session.draft = ReferenceLetterFixture.draft
        return (session, service)
    }
}
