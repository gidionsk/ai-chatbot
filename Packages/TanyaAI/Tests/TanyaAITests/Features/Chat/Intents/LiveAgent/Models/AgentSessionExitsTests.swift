//
//  AgentSessionExitsTests.swift
//  TanyaAITests
//
//  Created by Wendra on 23/11/26.
//

import Testing

@testable import TanyaAI

/// Posisi akhir sesi agen dari event `state` dan penanda tunggu setelah `leave-agent`.
struct AgentSessionExitsTests {
    /// Hanya perpindahan keluar dari antre atau agen yang dicatat, beserta apakah sesi itu dilayani agen; urut naik.
    @Test
    func onlyLeavingTheAgentIsRecorded() {
        var exits = AgentSessionExits()
        exits.record(change(.assistantActive, .agentQueued, seq: 3))
        exits.record(change(.agentQueued, .agentActive, seq: 4))
        exits.record(change(.agentActive, .assistantActive, seq: 9))
        exits.record(change(.agentQueued, .assistantActive, seq: 6))
        exits.record(change(.agentActive, .assistantActive, seq: nil))
        #expect(exits.marks == [.exit(seq: 6, isServed: false), .exit(seq: 9, isServed: true)])
    }

    /// Posisi tunggu dari `leave-agent` berlaku sampai event `state` keluar tiba, atau sesi baru dimulai.
    @Test
    func pendingExitEndsWithTheStateEventOrANewSession() {
        var exits = AgentSessionExits()
        exits.leave(.agentActive, afterSeq: 5)
        #expect(exits.marks == [.exit(seq: 5, isServed: true)])
        exits.record(change(.assistantActive, .assistantActive, seq: 5))
        #expect(exits.pending == .exit(seq: 5, isServed: true))
        exits.record(change(.agentActive, .assistantActive, seq: 6))
        #expect(exits.marks == [.exit(seq: 6, isServed: true)])

        exits.leave(.agentQueued, afterSeq: 7)
        #expect(exits.pending == .exit(seq: 7, isServed: false))
        exits.record(change(.assistantActive, .agentQueued, seq: 8))
        #expect(exits.pending == nil)
        exits.leave(.agentActive, afterSeq: nil)
        #expect(exits.marks == [.exit(seq: 6, isServed: true)])
    }

    private func change(
        _ previous: ConversationState,
        _ next: ConversationState,
        seq: Int?
    ) -> ConversationStateChange {
        ConversationStateChange(previous: previous, next: next, seq: seq)
    }
}
