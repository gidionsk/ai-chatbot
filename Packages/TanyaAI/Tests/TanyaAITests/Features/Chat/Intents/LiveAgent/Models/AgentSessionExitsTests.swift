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
    /// Hanya perpindahan keluar dari antre atau agen yang dicatat; posisi urut naik.
    @Test
    func onlyLeavingTheAgentIsRecorded() {
        var exits = AgentSessionExits()
        exits.record(change(.assistantActive, .agentQueued, seq: 3))
        exits.record(change(.agentQueued, .agentActive, seq: 4))
        exits.record(change(.agentActive, .assistantActive, seq: 9))
        exits.record(change(.agentQueued, .assistantActive, seq: 6))
        exits.record(change(.agentActive, .assistantActive, seq: nil))
        #expect(exits.positions == [6, 9])
    }

    /// Posisi tunggu dari `leave-agent` berlaku sampai event `state` keluar tiba, atau sesi baru dimulai.
    @Test
    func pendingExitEndsWithTheStateEventOrANewSession() {
        var exits = AgentSessionExits()
        exits.pendingSeq = 5
        #expect(exits.positions == [5])
        exits.record(change(.assistantActive, .assistantActive, seq: 5))
        #expect(exits.pendingSeq == 5)
        exits.record(change(.agentActive, .assistantActive, seq: 6))
        #expect(exits.positions == [6])

        exits.pendingSeq = 7
        exits.record(change(.assistantActive, .agentQueued, seq: 8))
        #expect(exits.pendingSeq == nil)
        #expect(exits.positions == [6])
    }

    private func change(
        _ previous: ConversationState,
        _ next: ConversationState,
        seq: Int?
    ) -> ConversationStateChange {
        ConversationStateChange(previous: previous, next: next, seq: seq)
    }
}
