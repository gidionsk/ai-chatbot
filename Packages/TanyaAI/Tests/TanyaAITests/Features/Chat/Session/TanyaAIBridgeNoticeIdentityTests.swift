//
//  TanyaAIBridgeNoticeIdentityTests.swift
//  TanyaAI
//
//  Created by Wendra on 14/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// `seq` kartu live agent menjadi id baris table. Gateway yang memberi `id:` SSE dari urutan lain bisa mengirim kartu
/// ber-`seq` sama dengan pesan agen di history; id ganda membuat table crash, jadi kartu itu hanya tampil sekali.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeNoticeIdentityTests {
    @Test
    func aStreamCardSharingTheSeqOfAnAgentMessageShowsOnce() async {
        let transport = FakeChatTransport()
        let messages = [3, 2, 1].map { WireFixture.message(seq: $0, direction: $0 == 3 ? "agent" : nil) }
        transport.historyPages = [WireFixture.history(messages: messages)]
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .ended, seq: 3)])
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_idle_timeout"))
        await waitUntil { bridge.liveAgentNotices.count == 1 }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .idleTimeout, seq: 3)])
        let items = [ChatListItem](rows: bridge.rows).inserting(bridge.visibleLiveAgentNotices, isLeaveEnabled: true)
        #expect(Set(items.map(\.id)).count == items.count)
    }

    /// Selama antre, kartu antre dan tombol batalnya yang dipertahankan, bukan kartu selesai dari history.
    @Test
    func theActiveQueueCardWinsOverAHistoryCardWithTheSameSeq() async {
        let transport = FakeChatTransport()
        let messages = [3, 2, 1].map { WireFixture.message(seq: $0, direction: $0 == 3 ? "agent" : nil) }
        transport.historyPages = [WireFixture.history(messages: messages)]
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_connecting"))
        transport.emit(WireFixture.stateFrame(seq: 4, state: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentQueued }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connecting, seq: 3)])
        let items = [ChatListItem](rows: bridge.rows).inserting(bridge.visibleLiveAgentNotices, isLeaveEnabled: true)
        #expect(items.contains(.leaveAgentQueue(isEnabled: true)))
        #expect(Set(items.map(\.id)).count == items.count)
    }
}
