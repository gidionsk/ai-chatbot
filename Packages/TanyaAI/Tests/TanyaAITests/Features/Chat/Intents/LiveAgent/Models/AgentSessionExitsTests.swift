//
//  AgentSessionExitsTests.swift
//  TanyaAITests
//
//  Created by Wendra on 23/11/26.
//

import Testing

@testable import TanyaAI

/// Batas sesi agen dari event `state` dan `leave-agent`.
struct AgentSessionExitsTests {
    /// Keluar dari antre atau agen dicatat beserta apakah sesi itu dilayani agen. Masuk ke antre dari state yang
    /// diketahui di luar antre menjadi awal antrean; antre ke dilayani agen dan state asal tak dikenal tidak.
    @Test
    func stateChangesBecomeSessionBounds() {
        var exits = AgentSessionExits()
        exits.record(change(.assistantActive, .agentQueued, seq: 3))
        exits.record(change(.agentQueued, .agentActive, seq: 4))
        exits.record(change(.agentActive, .assistantActive, seq: 9))
        exits.record(change(.agentQueued, .assistantActive, seq: 6))
        exits.record(change(.unknown, .agentActive, seq: 10))
        exits.record(change(.agentActive, .assistantActive, seq: nil))
        let expected: [AgentSessionMark] = [
            .queued(seq: 3), .exit(seq: 6, isServed: false), .exit(seq: 9, isServed: true)
        ]
        #expect(exits.marks == expected)
    }

    /// Posisi tunggu `leave-agent` disimpan dan tidak dibuang oleh event keluar resmi; scan yang menentukan
    /// sesinya. Tanpa `seq` tidak ada yang dicatat.
    @Test
    func leavingPositionIsKeptWithTheStateEvents() {
        var exits = AgentSessionExits()
        exits.leave(.agentActive, afterSeq: nil)
        #expect(exits.marks.isEmpty)
        exits.leave(.agentQueued, afterSeq: 5)
        exits.record(change(.agentActive, .assistantActive, seq: 7))
        #expect(exits.marks == [.leaving(seq: 5, isServed: false), .exit(seq: 7, isServed: true)])
    }

    private func change(
        _ previous: ConversationState,
        _ next: ConversationState,
        seq: Int?
    ) -> ConversationStateChange {
        ConversationStateChange(previous: previous, next: next, seq: seq)
    }
}
