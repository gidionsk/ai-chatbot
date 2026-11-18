//
//  TanyaAIBridgeQueueCardTests.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Kartu antre hanya milik antrean yang sedang berjalan, dan hilang begitu penggantinya datang dari stream.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeQueueCardTests {
    /// Event setelah antrean dimulai langsung menggantikan kartu antre, walau event `state` terlambat datang.
    @Test(arguments: [LiveAgentNoticeKind.joined, .canceled])
    func laterQueueEventHidesTheQueueCardBeforeTheState(kind: LiveAgentNoticeKind) async {
        let (transport, bridge) = await connectedBridge(states: ["ASSISTANT_ACTIVE"])
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_connecting"))
        transport.emit(WireFixture.stateFrame(seq: 4, state: "AGENT_QUEUED"))
        transport.emit(WireFixture.systemFrame(seq: 5, type: kind.rawValue))
        await waitUntil { bridge.eventCursor == 5 }
        #expect(bridge.conversationState == .agentQueued)
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: kind, seq: 5)])
    }

    /// Antre dari init tanpa event antre: `agent_joined` menutup kartu, dan pesan nasabah yang datang sebelum event
    /// `state` tidak memunculkannya lagi.
    @Test
    func customerMessageAfterTheJoinKeepsTheQueueCardHidden() async {
        let (transport, bridge) = await connectedBridge(states: ["AGENT_QUEUED"])
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_joined"))
        await waitUntil { bridge.eventCursor == 3 }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .joined, seq: 3)])
        transport.emit(WireFixture.messageFrame(seq: 4, direction: "user"))
        await waitUntil { bridge.messages.count == 3 }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .joined, seq: 3)])
    }

    /// Antrean pertama dibatalkan, lalu menyambung ulang ke antrean kedua yang event antre-nya tidak ikut replay:
    /// batal yang lama tidak menyembunyikan kartu antrean kedua, yang tampil di akhir daftar.
    @Test
    func aSecondQueueWithoutItsEventStillShowsTheCard() async {
        let (transport, bridge) = await connectedBridge(states: ["ASSISTANT_ACTIVE", "AGENT_QUEUED"])
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_connecting"))
        transport.emit(WireFixture.stateFrame(seq: 4, state: "AGENT_QUEUED"))
        transport.emit(WireFixture.systemFrame(seq: 5, type: "queue_canceled"))
        transport.emit(WireFixture.stateFrame(seq: 6, state: "ASSISTANT_ACTIVE", previous: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .assistantActive }
        transport.drop()
        await waitUntil { bridge.conversationState == .agentQueued }
        let expected = [LiveAgentNotice(kind: .canceled, seq: 5), .init(kind: .connecting, seq: .max)]
        #expect(bridge.visibleLiveAgentNotices == expected)
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeQueueCardTests {
    /// History seq 1 (user) dan 2 (bot); `states` = state init berurutan, yang terakhir dipakai seterusnya.
    func connectedBridge(states: [String]) async -> (FakeChatTransport, TanyaAIBridge) {
        let transport = FakeChatTransport()
        transport.initResults = states.map { .success(WireFixture.initialize(state: $0)) }
        transport.historyPages = [WireFixture.history([2, 1])]
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        return (transport, bridge)
    }
}
