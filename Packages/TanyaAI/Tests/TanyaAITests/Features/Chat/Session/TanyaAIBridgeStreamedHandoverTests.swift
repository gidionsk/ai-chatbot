//
//  TanyaAIBridgeStreamedHandoverTests.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Serah terima yang datang lewat stream ditutup oleh event stream, bukan kartu "tidak dilanjutkan" dari history.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeStreamedHandoverTests {
    /// Serah terima dari stream tanpa turn halaman ini (kanal lain, atau `state` antre yang terlambat): tidak ada kartu
    /// sampai event antre tiba, lalu kartu penutup dari stream.
    @Test
    func streamedHandoverWaitsForItsQueueEvents() async {
        let (transport, bridge) = await connectedBridge(history: [])
        defer { bridge.connectionTask?.cancel() }
        transport.emit(handoverFrame(seq: 2))
        await waitUntil { bridge.messages.last?.intent == .liveAgent }
        #expect(bridge.visibleLiveAgentNotices.isEmpty)
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_connecting"))
        transport.emit(WireFixture.stateFrame(seq: 4, state: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentQueued }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connecting, seq: 3)])
        transport.emit(WireFixture.systemFrame(seq: 5, type: "queue_canceled"))
        transport.emit(WireFixture.stateFrame(seq: 6, state: "ASSISTANT_ACTIVE", previous: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .assistantActive }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .canceled, seq: 5)])
    }

    /// Putus sebelum event antre tiba lalu bot menjawab lagi: setelah history disinkronkan, kartu "tidak
    /// dilanjutkan" kembali dibuat karena event penutupnya bisa sudah terpangkas.
    @Test
    func historySyncAfterAStreamedHandoverRestoresTheUnfinishedCard() async {
        let reconnectHistory = [WireFixture.message(seq: 4), handover(seq: 2), WireFixture.message(seq: 1)]
        let (transport, bridge) = await connectedBridge(history: [WireFixture.message(seq: 1)], next: reconnectHistory)
        defer { bridge.connectionTask?.cancel() }
        transport.emit(handoverFrame(seq: 2))
        await waitUntil { bridge.messages.count == 2 }
        #expect(bridge.visibleLiveAgentNotices.isEmpty)
        transport.drop()
        await waitUntil { bridge.messages.count == 3 }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .notContinued, seq: 2)])
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeStreamedHandoverTests {
    func handover(seq: Int) -> String {
        WireFixture.message(seq: seq, direction: "assistant", intent: ChatIntent.liveAgent.rawValue)
    }

    func handoverFrame(seq: Int) -> [String] {
        ["id: \(seq)", "event: message", "data: \(handover(seq: seq))", ""]
    }

    /// `next` = history saat menyambung ulang; kosong = history yang sama.
    func connectedBridge(history: [String], next: [String] = []) async -> (FakeChatTransport, TanyaAIBridge) {
        let transport = FakeChatTransport()
        transport.initResults = [.success(WireFixture.initialize()), .success(WireFixture.initialize())]
        let pages = next.isEmpty ? [history] : [history, next]
        transport.historyPages = pages.map { WireFixture.history(messages: $0) }
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        return (transport, bridge)
    }
}
