//
//  TanyaAIBridgeLiveAgentTests.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Live agent: state dari init dan stream, kirim tanpa turn lock, kartu status, dan keluar antrean.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeLiveAgentTests {
    /// Contract §7.5: selama antre atau dengan agen tidak ada `turn_end`, jadi tombol tidak boleh tertahan di stop.
    @Test(arguments: ["AGENT_QUEUED", "AGENT_ACTIVE"])
    func agentStatesFromInitDoNotLockSending(state: String) async {
        let (transport, bridge) = await connectedBridge(state: state)
        defer { bridge.connectionTask?.cancel() }
        #expect(await bridge.sendAndWait("Halo"))
        #expect(bridge.turnPhase == .idle)
        #expect(await bridge.sendAndWait("Masih di sana?"))
        #expect(transport.calls.filter { $0.hasPrefix("send:") }.count == 2)
    }

    /// Event `state` dari stream memindahkan kunci: ke agen = bebas kirim, kembali ke bot = dikunci lagi.
    @Test
    func stateEventsSwitchTheTurnLock() async {
        let (transport, bridge) = await connectedBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.stateFrame(seq: 3, state: "AGENT_ACTIVE", previous: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentActive }
        #expect(await bridge.sendAndWait("Halo agen"))
        #expect(bridge.turnPhase == .idle)
        transport.emit(WireFixture.stateFrame(seq: 5, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.conversationState == .assistantActive }
        #expect(await bridge.sendAndWait("Halo bot"))
        #expect(bridge.turnPhase == .awaitingReply)
    }

    /// Bot menyerahkan ke agen di tengah turn: kunci tetap dibuka oleh `turn_end` turn itu.
    @Test
    func handoverTurnStillEndsWithItsTurnEnd() async {
        let (transport, bridge) = await connectedBridge()
        defer { bridge.connectionTask?.cancel() }
        #expect(await bridge.sendAndWait("Saya mau live agent"))
        transport.emit(WireFixture.stateFrame(seq: 3, state: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentQueued }
        #expect(bridge.turnPhase == .awaitingReply)
        transport.emit(WireFixture.turnEndFrame(seq: 4))
        await waitUntil { bridge.turnPhase == .idle }
    }

    /// Replay setelah reconnect mengulang event yang sama; kartu tidak dobel dan tetap urut `seq`.
    @Test
    func noticesKeepTheirSeqOrderWithoutDuplicates() async {
        let (transport, bridge) = await connectedBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 7, type: "queue_canceled"))
        transport.emit(WireFixture.systemFrame(seq: 4, type: "agent_connecting"))
        transport.emit(WireFixture.systemFrame(seq: 7, type: "queue_canceled"))
        transport.emit(WireFixture.systemFrame(seq: 8, type: "agent_joined"))
        await waitUntil { bridge.eventCursor == 8 }
        #expect(bridge.liveAgentNotices == [.init(kind: .connecting, seq: 4), .init(kind: .canceled, seq: 7)])
    }

    /// Kartu milik percakapan lama tidak terbawa saat init memberi percakapan lain.
    @Test
    func noticesAreClearedWhenTheConversationChanges() async {
        let transport = FakeChatTransport()
        transport.initResults = [
            .success(WireFixture.initialize()), .success(WireFixture.initialize(conversationID: "lain"))
        ]
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        Task { await bridge.run() }
        defer { bridge.connectionTask?.cancel() }
        await waitUntil { bridge.connection == .live }
        transport.emit(WireFixture.systemFrame(seq: 4, type: "agent_ended"))
        await waitUntil { !bridge.liveAgentNotices.isEmpty }
        transport.drop()
        await waitUntil { bridge.conversationID == "lain" }
        #expect(bridge.liveAgentNotices.isEmpty)
    }

    /// `left:true` = langsung kembali ke bot, kirim dikunci lagi; tombol tidak dikirim ulang selama diproses.
    @Test
    func leavingTheQueueReturnsToTheAssistant() async {
        let (transport, bridge) = await connectedBridge(state: "AGENT_QUEUED")
        defer { bridge.connectionTask?.cancel() }
        await bridge.leaveAgentQueue()
        #expect(transport.calls.filter { $0 == "leave" }.count == 1)
        #expect(bridge.conversationState == .assistantActive)
        #expect(!bridge.isLeavingAgentQueue)
        await bridge.leaveAgentQueue()
        #expect(transport.calls.filter { $0 == "leave" }.count == 1, "sudah tidak antre")
    }

    /// `left:false`, 409 (agen sudah bergabung), atau gagal lain: state menunggu event dari stream, tombol aktif lagi.
    @Test(arguments: [
        Result<Data, Error>.success(WireFixture.leave(isLeft: false)),
        .failure(TanyaAITransportError.response(statusCode: 409, body: WireFixture.error(isRetryable: false))),
        .success(Data("{}".utf8))
    ])
    func unacceptedLeaveKeepsTheQueue(result: Result<Data, Error>) async {
        let (transport, bridge) = await connectedBridge(state: "AGENT_QUEUED")
        defer { bridge.connectionTask?.cancel() }
        transport.leaveResult = result
        await bridge.leaveAgentQueue()
        #expect(bridge.conversationState == .agentQueued)
        #expect(!bridge.isLeavingAgentQueue)
        #expect(bridge.connection == .live)
    }

    @Test
    func unauthorizedLeaveExpiresTheSession() async {
        let (transport, bridge) = await connectedBridge(state: "AGENT_QUEUED")
        defer { bridge.connectionTask?.cancel() }
        let unauthorized = TanyaAITransportError.response(statusCode: 401, body: WireFixture.error(isRetryable: false))
        transport.leaveResult = .failure(unauthorized)
        await bridge.leaveAgentQueue()
        #expect(bridge.connection == .expired)
    }

    /// Respons keluar antrean milik percakapan yang sudah diganti init tidak mengubah percakapan baru.
    @Test(arguments: [
        Result<Data, Error>.success(WireFixture.leave(isLeft: true)),
        .failure(TanyaAITransportError.response(statusCode: 404, body: WireFixture.error(isRetryable: false)))
    ])
    func leaveResponseForAReplacedConversationIsIgnored(result: Result<Data, Error>) async {
        let (transport, bridge) = await connectedBridge(state: "AGENT_QUEUED")
        defer { bridge.connectionTask?.cancel() }
        transport.initResults = [.success(WireFixture.initialize(conversationID: "lain", state: "AGENT_QUEUED"))]
        transport.leaveResult = result
        transport.isHoldingLeave = true
        let leave = Task { await bridge.leaveAgentQueue() }
        await waitUntil { transport.isAckHeld }
        transport.drop()
        await waitUntil { bridge.conversationID == "lain" && bridge.connection == .live }
        transport.releaseAck()
        await leave.value
        #expect(bridge.conversationState == .agentQueued)
        #expect(bridge.connection == .live)
    }

    @Test(arguments: ["ASSISTANT_ACTIVE", "AGENT_ACTIVE"])
    func leaveOutsideTheQueueIsNotSent(state: String) async {
        let (transport, bridge) = await connectedBridge(state: state)
        defer { bridge.connectionTask?.cancel() }
        await bridge.leaveAgentQueue()
        #expect(!transport.calls.contains("leave"))
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeLiveAgentTests {
    /// Sambungan hidup dengan state init tertentu; test menghentikannya lewat `connectionTask` di akhir.
    func connectedBridge(state: String = "ASSISTANT_ACTIVE") async -> (FakeChatTransport, TanyaAIBridge) {
        let transport = FakeChatTransport()
        transport.initResults = [.success(WireFixture.initialize(state: state))]
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        return (transport, bridge)
    }
}
