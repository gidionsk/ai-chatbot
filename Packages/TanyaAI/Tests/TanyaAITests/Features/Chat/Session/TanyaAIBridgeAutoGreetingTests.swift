//
//  TanyaAIBridgeAutoGreetingTests.swift
//  TanyaAITests
//
//  Created by Wendra on 19/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Sapaan otomatis = pesan agen selama antre, sebelum agen bergabung (`AGENT_ACTIVE` baru terjadi saat agen benar-benar
/// bergabung). Kartu antre menjadi "Connected" tanpa tombol batal, lalu "Mencari customer assistant..." sampai agen
/// bergabung atau antrean ditutup.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeAutoGreetingTests {
    @Test
    func autoGreetingConnectsTheQueueCardAndSearchesUntilTheAgentJoins() async {
        let (transport, bridge) = await queuedBridge()
        defer { bridge.connectionTask?.cancel() }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connecting, seq: 3)])
        #expect(!bridge.isSearchingAgent)
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        await waitUntil { bridge.messages.count == 3 }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connected, seq: 3)])
        #expect(bridge.isSearchingAgent)
        let items = [ChatListItem](rows: bridge.rows).inserting(bridge.visibleLiveAgentNotices, isLeaveEnabled: true)
        #expect(!items.contains(.leaveAgentQueue(isEnabled: true)))
        transport.emit(WireFixture.systemFrame(seq: 6, type: "agent_joined"))
        await waitUntil { bridge.eventCursor == 6 }
        #expect(!bridge.isSearchingAgent)
        transport.emit(WireFixture.stateFrame(seq: 7, state: "AGENT_ACTIVE", previous: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentActive }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connected, seq: 3)])
    }

    /// Agen yang sedang mengetik didahulukan; indikator mencari kembali setelah agen berhenti mengetik.
    @Test
    func agentTypingTakesThePlaceOfSearching() async {
        let lifetime = 30
        let (transport, bridge) = await queuedBridge(pausing: TimeInterval(lifetime))
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        transport.emit(WireFixture.typingFrame(seq: 5, lifetime: lifetime))
        await waitUntil { bridge.isAgentTyping }
        #expect(!bridge.isSearchingAgent)
        transport.emit(WireFixture.typingFrame(seq: 5, isTyping: false))
        await waitUntil { !bridge.isAgentTyping }
        #expect(bridge.isSearchingAgent)
    }

    /// Antre habis setelah sapaan: berhenti mencari, kartu "Connected" tetap, dan tidak ada kartu selesai tambahan.
    @Test
    func aTimeoutAfterTheGreetingStopsSearching() async {
        let (transport, bridge) = await queuedBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        transport.emit(WireFixture.systemFrame(seq: 6, type: "queue_timeout"))
        transport.emit(WireFixture.stateFrame(seq: 7, state: "ASSISTANT_ACTIVE", previous: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .assistantActive }
        #expect(!bridge.isSearchingAgent)
        let expected = [LiveAgentNotice(kind: .connected, seq: 3), .init(kind: .queueTimeout, seq: 6)]
        #expect(bridge.visibleLiveAgentNotices == expected)
    }

    /// Antre habis setelah sapaan, lalu antre lagi tanpa jawaban bot di antaranya: sapaan lama bukan milik antrean
    /// baru, jadi kartu antre baru (dengan tombol batal) tampil dan belum mencari agen.
    @Test
    func anOldGreetingDoesNotConnectTheNextQueue() async {
        let (transport, bridge) = await queuedBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        transport.emit(WireFixture.systemFrame(seq: 6, type: "queue_timeout"))
        transport.emit(WireFixture.stateFrame(seq: 7, state: "ASSISTANT_ACTIVE", previous: "AGENT_QUEUED"))
        transport.emit(WireFixture.systemFrame(seq: 8, type: "agent_connecting"))
        transport.emit(WireFixture.stateFrame(seq: 9, state: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentQueued && bridge.eventCursor == 9 }
        let expected = [
            LiveAgentNotice(kind: .connected, seq: 3), .init(kind: .queueTimeout, seq: 6),
            .init(kind: .connecting, seq: 8)
        ]
        #expect(bridge.visibleLiveAgentNotices == expected)
        #expect(!bridge.isSearchingAgent)
    }

    /// Agen bergabung lalu menutup sesi tanpa mengirim pesan: kartu "Connected" tetap sebagai riwayat.
    @Test
    func aSessionWithoutAgentMessagesKeepsItsConnectedCard() async {
        let (transport, bridge) = await queuedBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 5, type: "agent_joined"))
        transport.emit(WireFixture.stateFrame(seq: 6, state: "AGENT_ACTIVE", previous: "AGENT_QUEUED"))
        transport.emit(WireFixture.systemFrame(seq: 7, type: "agent_ended"))
        transport.emit(WireFixture.stateFrame(seq: 8, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.conversationState == .assistantActive }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connected, seq: 3), .init(kind: .ended, seq: 7)])
    }

    /// Dibuka lagi saat masih antre dengan sapaan di history: "Connected" sebelum sapaan, dan masih mencari.
    @Test
    func reopeningTheQueueAfterTheGreetingStillSearches() async {
        let transport = FakeChatTransport()
        transport.initResults = [.success(WireFixture.initialize(state: "AGENT_QUEUED"))]
        let messages = [3, 2, 1].map { WireFixture.message(seq: $0, direction: $0 == 3 ? "agent" : nil) }
        transport.historyPages = [WireFixture.history(messages: messages)]
        let bridge = await connected(transport)
        defer { bridge.connectionTask?.cancel() }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connected, seq: 2)])
        #expect(bridge.isSearchingAgent)
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeAutoGreetingTests {
    /// History seq 1 (user) dan 2 (bot), lalu antre dari stream: event antre seq 3, state seq 4. `pausing` = jeda yang
    /// tertahan sampai test selesai, misalnya batas tampil indikator mengetik.
    func queuedBridge(pausing: TimeInterval? = nil) async -> (FakeChatTransport, TanyaAIBridge) {
        let transport = FakeChatTransport()
        transport.initResults = [.success(WireFixture.initialize())]
        transport.historyPages = [WireFixture.history([2, 1])]
        let bridge = await connected(transport, pausing: pausing)
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_connecting"))
        transport.emit(WireFixture.stateFrame(seq: 4, state: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentQueued }
        return (transport, bridge)
    }

    func connected(_ transport: FakeChatTransport, pausing: TimeInterval? = nil) async -> TanyaAIBridge {
        let sleep: (TimeInterval) async throws -> Void = { seconds in
            guard seconds == pausing else { return }
            try await Task.sleep(nanoseconds: 60_000_000_000)
        }
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: sleep)
        Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        return bridge
    }
}
