//
//  TanyaAIBridgeAgentNameTests.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Bar sesi agen menunggu nama agen: `AGENT_ACTIVE` tanpa nama (urutan stream UAT) belum dianggap agen manusia.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeAgentNameTests {
    /// Urutan UAT: `agent_joined` dan `AGENT_ACTIVE` dengan `agent: null` sebelum sapaan otomatis; nama datang
    /// belakangan.
    @Test
    func activeStateWithoutANameIsNotAHumanAgent() async {
        let (transport, bridge) = await connectedBridge(state: "AGENT_QUEUED")
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_joined", data: #"{"agent":null}"#))
        transport.emit(
            WireFixture.stateFrame(seq: 4, state: "AGENT_ACTIVE", previous: "AGENT_QUEUED", isAgentNamed: false))
        await waitUntil { bridge.conversationState == .agentActive }
        #expect(!bridge.isHumanAgentActive)
        transport.emit(WireFixture.systemFrame(seq: 5, type: "agent_joined", data: #"{"agent":{"name":"Durenk"}}"#))
        await waitUntil { bridge.isHumanAgentActive }
        #expect(bridge.agentName == "Durenk")
    }

    /// `agent_joined` bisa mendahului event `state`; namanya tetap dipakai setelah state berpindah.
    @Test
    func joinedNameBeforeTheStateEventIsKept() async {
        let (transport, bridge) = await connectedBridge(state: "AGENT_QUEUED")
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_joined", data: #"{"agent":{"name":"Durenk"}}"#))
        await waitUntil { bridge.agentName == "Durenk" }
        #expect(!bridge.isHumanAgentActive)
        transport.emit(
            WireFixture.stateFrame(seq: 4, state: "AGENT_ACTIVE", previous: "AGENT_QUEUED", isAgentNamed: false))
        await waitUntil { bridge.isHumanAgentActive }
    }

    /// Kembali ke bot melupakan nama, jadi antrean berikutnya tidak langsung dianggap dilayani agen lama.
    @Test
    func leavingTheAgentForgetsTheName() async {
        let (transport, bridge) = await connectedBridge(state: "AGENT_QUEUED")
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.stateFrame(seq: 3, state: "AGENT_ACTIVE", previous: "AGENT_QUEUED"))
        await waitUntil { bridge.isHumanAgentActive }
        transport.emit(WireFixture.stateFrame(seq: 4, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.conversationState == .assistantActive }
        #expect(bridge.agentName == nil)
        transport.emit(WireFixture.stateFrame(seq: 5, state: "AGENT_QUEUED"))
        transport.emit(
            WireFixture.stateFrame(seq: 6, state: "AGENT_ACTIVE", previous: "AGENT_QUEUED", isAgentNamed: false))
        await waitUntil { bridge.conversationState == .agentActive }
        #expect(!bridge.isHumanAgentActive)
    }

    /// Antrean baru dari sesi agen (mis. dikembalikan ke antre) juga melupakan agen sebelumnya.
    @Test
    func newQueueForgetsThePreviousAgent() async {
        let (transport, bridge) = await connectedBridge(state: "AGENT_QUEUED")
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.stateFrame(seq: 3, state: "AGENT_ACTIVE", previous: "AGENT_QUEUED"))
        await waitUntil { bridge.isHumanAgentActive }
        transport.emit(WireFixture.stateFrame(seq: 4, state: "AGENT_QUEUED", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.conversationState == .agentQueued }
        #expect(bridge.agentName == nil)
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeAgentNameTests {
    /// Sambungan hidup dengan state init tertentu; test menghentikannya lewat `connectionTask` di akhir.
    func connectedBridge(state: String) async -> (FakeChatTransport, TanyaAIBridge) {
        let transport = FakeChatTransport()
        transport.initResults = [.success(WireFixture.initialize(state: state))]
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        return (transport, bridge)
    }
}
