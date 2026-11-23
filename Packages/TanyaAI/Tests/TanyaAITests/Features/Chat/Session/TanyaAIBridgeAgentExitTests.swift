//
//  TanyaAIBridgeAgentExitTests.swift
//  TanyaAITests
//
//  Created by Wendra on 23/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Kartu selesai sesi agen di posisi event `state` yang keluar dari agen. Pesan nasabah selama sesi, termasuk yang
/// dikirim sebelum agen manusia bergabung, tetap di atas kartu, baik dari stream langsung, setelah `leave-agent`,
/// maupun saat event itu datang lewat replay setelah history dimuat.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeAgentExitTests {
    /// Urutan UAT: pesan nasabah, `state` AGENT_ACTIVE → ASSISTANT_ACTIVE, lalu `agent_left` yang tidak dikenal.
    @Test
    func userMessageDuringTheSessionStaysAboveTheEndedCard() async {
        let transport = FakeChatTransport()
        let bridge = await connectedBridge(transport, state: "AGENT_ACTIVE")
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        transport.emit(WireFixture.messageFrame(seq: 6, direction: "user"))
        transport.emit(WireFixture.stateFrame(seq: 7, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        transport.emit(WireFixture.systemFrame(seq: 8, type: "agent_left"))
        await waitUntil { bridge.eventCursor == 8 }
        #expect(itemIDs(bridge).suffix(3) == [.message("m-5"), .message("m-6"), .liveAgentNotice(7)])
    }

    /// `left:true` tiba sebelum event `state`: kartu sementara di ujung daftar, lalu pindah ke `seq` event itu tanpa
    /// berganti tempat terhadap pesan.
    @Test
    func leavingKeepsTheEndedCardBelowTheSessionMessages() async {
        let transport = FakeChatTransport()
        let bridge = await connectedBridge(transport, state: "AGENT_ACTIVE")
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        transport.emit(WireFixture.messageFrame(seq: 6, direction: "user"))
        await waitUntil { bridge.messages.count == 4 }
        await bridge.leaveAgent(from: bridge.agentSessionKey)
        #expect(bridge.conversationState == .assistantActive)
        #expect(itemIDs(bridge).suffix(2) == [.message("m-6"), .liveAgentNotice(.max)])

        transport.emit(WireFixture.stateFrame(seq: 7, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.eventCursor == 7 }
        #expect(!bridge.agentExits.isPending)
        #expect(itemIDs(bridge).suffix(2) == [.message("m-6"), .liveAgentNotice(7)])
    }

    /// History tidak membawa event `state`: kartu menebak dari pesan agen terakhir, lalu dipetakan ulang begitu event
    /// itu datang lewat replay stream.
    @Test
    func replayedStateEventRemapsTheHistoryCard() async {
        let transport = FakeChatTransport()
        let history = [
            WireFixture.message(seq: 11, direction: "user"), WireFixture.message(seq: 10, direction: "agent"),
            WireFixture.message(seq: 9, direction: "assistant")
        ]
        let bridge = await connectedBridge(transport, state: "ASSISTANT_ACTIVE", history: history)
        defer { bridge.connectionTask?.cancel() }
        #expect(itemIDs(bridge).suffix(3) == [.message("m-10"), .liveAgentNotice(10), .message("m-11")])

        transport.emit(WireFixture.stateFrame(seq: 12, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.eventCursor == 12 }
        #expect(itemIDs(bridge).suffix(3) == [.message("m-10"), .message("m-11"), .liveAgentNotice(12)])
    }

    /// Percakapan lain dari init membuang posisi akhir sesi percakapan lama.
    @Test
    func anotherConversationForgetsTheExits() async {
        let transport = FakeChatTransport()
        let bridge = await connectedBridge(transport, state: "AGENT_ACTIVE")
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.stateFrame(seq: 7, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.eventCursor == 7 }
        #expect(bridge.agentExits.positions == [7])
        bridge.replaceOrMerge([], conversationID: "other")
        #expect(bridge.agentExits.positions.isEmpty)
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeAgentExitTests {
    /// Jeda (backoff, indikator mengetik) langsung selesai.
    func connectedBridge(
        _ transport: FakeChatTransport,
        state: String,
        history: [String]? = nil
    ) async -> TanyaAIBridge {
        transport.initResults = [.success(WireFixture.initialize(state: state))]
        transport.historyPages = [history.map { WireFixture.history(messages: $0) } ?? WireFixture.history([2, 1])]
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        return bridge
    }

    func itemIDs(_ bridge: TanyaAIBridge) -> [ChatListItemID] {
        [ChatListItem](rows: bridge.rows).inserting(bridge.visibleLiveAgentNotices, isLeaveEnabled: true).map(\.id)
    }
}
