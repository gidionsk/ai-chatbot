//
//  TanyaAIBridgeLeaveSessionTests.swift
//  TanyaAITests
//
//  Created by Wendra on 20/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Konfirmasi End Session menyimpan antrean atau sesi saat tombol diketuk; bridge mengeceknya lagi tepat sebelum
/// `leave-agent`. Sesi lain tidak ikut diakhiri, sedangkan antre yang berlanjut menjadi dilayani agen tetap bisa.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeLeaveSessionTests {
    /// Reconnect ke percakapan lain yang juga dilayani agen: bar tetap tampil, tetapi Yes dari konfirmasi lama tidak
    /// mengirim `leave-agent` untuk percakapan baru.
    @Test
    func aConfirmationFromAnotherConversationSendsNoLeave() async {
        let (transport, bridge) = await connectedBridge(state: "AGENT_ACTIVE")
        defer { bridge.connectionTask?.cancel() }
        let session = bridge.agentSessionKey
        transport.initResults = [.success(WireFixture.initialize(conversationID: "lain", state: "AGENT_ACTIVE"))]
        transport.drop()
        await waitUntil { bridge.conversationID == "lain" && bridge.connection == .live }
        #expect(bridge.isAgentSessionBannerVisible)
        #expect(bridge.agentSessionKey != session)
        await bridge.leaveAgent(from: session)
        #expect(!transport.calls.contains("leave"))
        #expect(bridge.conversationState == .agentActive)
    }

    /// Konfirmasi dibuka setelah sapaan selama antre, lalu agen bergabung sebelum Yes: masih antrean yang sama.
    @Test
    func aConfirmationFromTheQueueStillLeavesAfterTheAgentJoins() async {
        let (transport, bridge) = await connectedBridge(state: "AGENT_QUEUED")
        defer { bridge.connectionTask?.cancel() }
        let session = bridge.agentSessionKey
        transport.emit(WireFixture.stateFrame(seq: 5, state: "AGENT_ACTIVE", previous: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentActive }
        #expect(bridge.agentSessionKey == session)
        await bridge.leaveAgent(from: session)
        #expect(transport.calls.filter { $0 == "leave" }.count == 1)
        #expect(bridge.conversationState == .assistantActive)
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeLeaveSessionTests {
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
