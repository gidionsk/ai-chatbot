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
    /// Event penutup antrean langsung menggantikan kartu antre, walau event `state` terlambat datang.
    @Test(arguments: [LiveAgentNoticeKind.canceled, .queueTimeout])
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

    /// Agen bergabung sebelum event `state`: kartu antre langsung menjadi "Connected" di posisi yang sama.
    @Test
    func aJoinBeforeTheStateTurnsTheQueueCardIntoConnected() async {
        let (transport, bridge) = await connectedBridge(states: ["ASSISTANT_ACTIVE"])
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_connecting"))
        transport.emit(WireFixture.stateFrame(seq: 4, state: "AGENT_QUEUED"))
        transport.emit(WireFixture.systemFrame(seq: 5, type: "agent_joined"))
        await waitUntil { bridge.eventCursor == 5 }
        #expect(bridge.conversationState == .agentQueued)
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connected, seq: 3)])
    }

    /// Antre dari init tanpa event antre: `agent_joined` mengubah kartu menjadi "Connected", dan pesan nasabah yang
    /// datang sebelum event `state` tidak mengembalikan kartu antre.
    @Test
    func customerMessageAfterTheJoinKeepsTheConnectedCard() async {
        let (transport, bridge) = await connectedBridge(states: ["AGENT_QUEUED"])
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_joined"))
        await waitUntil { bridge.eventCursor == 3 }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connected, seq: 3)])
        transport.emit(WireFixture.messageFrame(seq: 4, direction: "user"))
        await waitUntil { bridge.messages.count == 3 }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connected, seq: 3)])
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

    /// Antrean pertama habis lalu putus sebelum event `state`; init masih antre (antrean kedua, nilai state sama):
    /// antre habis yang lama tidak menyembunyikan kartu antrean kedua.
    @Test
    func aTimedOutQueueDoesNotHideTheNextQueueWithTheSameState() async {
        let (transport, bridge) = await connectedBridge(states: ["ASSISTANT_ACTIVE", "AGENT_QUEUED"])
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_connecting"))
        transport.emit(WireFixture.stateFrame(seq: 4, state: "AGENT_QUEUED"))
        transport.emit(WireFixture.systemFrame(seq: 5, type: "queue_timeout"))
        await waitUntil { bridge.eventCursor == 5 }
        transport.drop()
        await waitUntil { transport.calls.filter { $0 == "init" }.count == 2 && bridge.connection == .live }
        let expected = [LiveAgentNotice(kind: .queueTimeout, seq: 5), .init(kind: .connecting, seq: .max)]
        #expect(bridge.visibleLiveAgentNotices == expected)
    }

    /// Percakapan berganti saat antre dengan seq yang mulai dari kecil lagi: acuan antrean ikut percakapan baru.
    @Test
    func aNewConversationResetsTheQueueReference() async {
        let transport = FakeChatTransport()
        transport.initResults = [
            .success(WireFixture.initialize(state: "AGENT_QUEUED")),
            .success(WireFixture.initialize(conversationID: "percakapan-baru", state: "AGENT_QUEUED"))
        ]
        transport.historyPages = [WireFixture.history([20, 19]), WireFixture.history([])]
        let bridge = await connected(transport)
        defer { bridge.connectionTask?.cancel() }
        transport.drop()
        await waitUntil { bridge.messages.isEmpty }
        transport.emit(WireFixture.systemFrame(seq: 1, type: "agent_joined"))
        await waitUntil { bridge.eventCursor == 1 }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connected, seq: 1)])
    }

    /// Penutup antrean lama terlewat saat putus, lalu bot menjawab dan menyerahkan lagi: event antre lama bukan
    /// pembuka antrean ini, jadi kartu dan tombol batal di akhir daftar, bukan di bawah serah terima lama.
    @Test
    func anOldQueueEventIsNotTheOpenerAfterANewBotReply() async {
        let transport = FakeChatTransport()
        transport.initResults = [
            .success(WireFixture.initialize()), .success(WireFixture.initialize(state: "AGENT_QUEUED"))
        ]
        let handover = WireFixture.message(seq: 8, intent: ChatIntent.liveAgent.rawValue)
        let reconnect = [handover] + [6, 2, 1].map { WireFixture.message(seq: $0) }
        transport.historyPages = [WireFixture.history([2, 1]), WireFixture.history(messages: reconnect)]
        let bridge = await connected(transport)
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_connecting"))
        transport.emit(WireFixture.stateFrame(seq: 4, state: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentQueued }
        transport.drop()
        await waitUntil { bridge.messages.count == 4 }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connecting, seq: .max)])
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeQueueCardTests {
    /// History seq 1 (user) dan 2 (bot); `states` = state init berurutan, yang terakhir dipakai seterusnya.
    func connectedBridge(states: [String]) async -> (FakeChatTransport, TanyaAIBridge) {
        let transport = FakeChatTransport()
        transport.initResults = states.map { .success(WireFixture.initialize(state: $0)) }
        transport.historyPages = [WireFixture.history([2, 1])]
        return (transport, await connected(transport))
    }

    func connected(_ transport: FakeChatTransport) async -> TanyaAIBridge {
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        return bridge
    }
}
