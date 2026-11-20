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
/// bergabung). Kartu Switching (dengan tombol batal, composer terkunci) menjadi "Connected", dan sejak itu bar sesi
/// agen dengan End Session tampil sampai antrean atau sesi ditutup.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeAutoGreetingTests {
    @Test
    func autoGreetingEndsSwitchingAndShowsTheSessionBar() async {
        let (transport, bridge) = await queuedBridge()
        defer { bridge.connectionTask?.cancel() }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connecting, seq: 3)])
        #expect(bridge.isSwitchingToAgent)
        #expect(!bridge.isAgentSessionBannerVisible)
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        await waitUntil { bridge.messages.count == 3 }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connected, seq: 3)])
        #expect(!bridge.isSwitchingToAgent)
        #expect(bridge.isAgentSessionBannerVisible)
        let items = [ChatListItem](rows: bridge.rows).inserting(bridge.visibleLiveAgentNotices, isLeaveEnabled: true)
        #expect(items.contains(.liveAgentNotice(.init(kind: .connected, seq: 3), isLeaveEnabled: false)))
        transport.emit(WireFixture.systemFrame(seq: 6, type: "agent_joined"))
        transport.emit(WireFixture.stateFrame(seq: 7, state: "AGENT_ACTIVE", previous: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentActive }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connected, seq: 3)])
        #expect(bridge.isAgentSessionBannerVisible)
    }

    /// Urutan UAT: `agent_joined` dan `AGENT_ACTIVE` datang sebelum sapaan; kartu Switching sudah selesai saat agen
    /// bergabung, jadi bar langsung tampil tanpa menunggu pesan agen atau nama agen.
    @Test
    func joiningBeforeTheGreetingShowsTheSessionBar() async {
        let (transport, bridge) = await queuedBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 5, type: "agent_joined"))
        await waitUntil { bridge.eventCursor == 5 }
        #expect(!bridge.isSwitchingToAgent)
        #expect(bridge.isAgentSessionBannerVisible)
        transport.emit(WireFixture.stateFrame(seq: 6, state: "AGENT_ACTIVE", previous: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentActive }
        #expect(bridge.isAgentSessionBannerVisible)
    }

    /// Batal antre setelah sapaan: bar hilang begitu event penutup tiba, walau event `state` belum datang.
    @Test
    func aClosingEventHidesTheSessionBarBeforeTheStateEvent() async {
        let (transport, bridge) = await queuedBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        transport.emit(WireFixture.systemFrame(seq: 6, type: "queue_canceled"))
        await waitUntil { bridge.eventCursor == 6 }
        #expect(bridge.conversationState == .agentQueued)
        #expect(!bridge.isAgentSessionBannerVisible)
        #expect(!bridge.isSwitchingToAgent)
    }

    /// Antre habis setelah sapaan: bar hilang, kartu "Connected" tetap, dan tidak ada kartu selesai tambahan.
    @Test
    func aTimeoutAfterTheGreetingHidesTheSessionBar() async {
        let (transport, bridge) = await queuedBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        transport.emit(WireFixture.systemFrame(seq: 6, type: "queue_timeout"))
        transport.emit(WireFixture.stateFrame(seq: 7, state: "ASSISTANT_ACTIVE", previous: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .assistantActive }
        #expect(!bridge.isAgentSessionBannerVisible)
        let expected = [LiveAgentNotice(kind: .connected, seq: 3), .init(kind: .queueTimeout, seq: 6)]
        #expect(bridge.visibleLiveAgentNotices == expected)
    }

    /// Antre habis setelah sapaan, lalu antre lagi tanpa jawaban bot di antaranya: sapaan lama bukan milik antrean
    /// baru, jadi kartu Switching baru (dengan tombol batal) tampil dan bar sesi agen belum tampil.
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
        #expect(bridge.isSwitchingToAgent)
        #expect(!bridge.isAgentSessionBannerVisible)
    }

    /// Event penutup antrean lama terlewat (replay terpangkas), lalu event antre baru datang: sapaan lama bukan milik
    /// antrean baru, dan sapaan berikutnya memberi kartu "Connected" kedua di posisi event antre baru.
    @Test
    func aNewQueueEventStartsANewSessionWithoutTheOldClosingEvent() async {
        let (transport, bridge) = await queuedBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        transport.emit(WireFixture.systemFrame(seq: 8, type: "agent_connecting"))
        await waitUntil { bridge.eventCursor == 8 }
        let queued = [LiveAgentNotice(kind: .connected, seq: 3), .init(kind: .connecting, seq: 8)]
        #expect(bridge.visibleLiveAgentNotices == queued)
        #expect(!bridge.isAgentSessionBannerVisible)
        transport.emit(WireFixture.messageFrame(seq: 9, direction: "agent"))
        await waitUntil { bridge.messages.count == 4 }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connected, seq: 3), .init(kind: .connected, seq: 8)])
        #expect(bridge.isAgentSessionBannerVisible)
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

    /// Dibuka lagi saat masih antre dengan sapaan di history: "Connected" sebelum sapaan, dan bar sesi agen tampil.
    @Test
    func reopeningTheQueueAfterTheGreetingShowsTheSessionBar() async {
        let transport = FakeChatTransport()
        transport.initResults = [.success(WireFixture.initialize(state: "AGENT_QUEUED"))]
        let messages = [3, 2, 1].map { WireFixture.message(seq: $0, direction: $0 == 3 ? "agent" : nil) }
        transport.historyPages = [WireFixture.history(messages: messages)]
        let bridge = await connected(transport)
        defer { bridge.connectionTask?.cancel() }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connected, seq: 2)])
        #expect(bridge.isAgentSessionBannerVisible)
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeAutoGreetingTests {
    /// History seq 1 (user) dan 2 (bot), lalu antre dari stream: event antre seq 3, state seq 4.
    func queuedBridge() async -> (FakeChatTransport, TanyaAIBridge) {
        let transport = FakeChatTransport()
        transport.initResults = [.success(WireFixture.initialize())]
        transport.historyPages = [WireFixture.history([2, 1])]
        let bridge = await connected(transport)
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_connecting"))
        transport.emit(WireFixture.stateFrame(seq: 4, state: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentQueued }
        return (transport, bridge)
    }

    /// Jeda (backoff, indikator mengetik) langsung selesai.
    func connected(_ transport: FakeChatTransport) async -> TanyaAIBridge {
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        return bridge
    }
}
