//
//  ChatBackoffTests.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Testing

@testable import TanyaAI

struct ChatBackoffTests {
    @Test
    func delaysDoubleUpToThirtySecondsAndResetAfterAConnection() {
        var backoff = ChatBackoff()
        #expect((0..<7).map { _ in backoff.nextDelay() } == [1, 2, 4, 8, 16, 30, 30])
        backoff.reset()
        #expect(backoff.nextDelay() == 1)
    }

    @Test
    func serverRetryAfterWinsButStillCountsAsAFailure() {
        var backoff = ChatBackoff()
        #expect(backoff.nextDelay(retryAfterMilliseconds: 5_000) == 5)
        #expect(backoff.nextDelay() == 2)
    }

    @Test
    func onlyServerErrorsAreRetriedWhenTheBodyIsNotAnEnvelope() {
        #expect(ChatBackoff.isServerError(statusCode: 503))
        #expect(!ChatBackoff.isServerError(statusCode: 404))
        #expect(ChatBackoff.isUnauthorized(statusCode: 401))
    }
}
