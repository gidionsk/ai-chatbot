//
//  TanyaAIBridgeUserTypingTests.swift
//  TanyaAI
//
//  Created by Wendra on 11/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Sinyal nasabah mengetik ke agen (contract §7.7): hanya selama dilayani agen, dibatasi frekuensinya, dan berurutan.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeUserTypingTests {
    /// Ketikan beruntun cukup satu `typing:true`; draft kosong mengirim satu `typing:false`.
    @Test
    func typingIsSentOnceUntilTheDraftIsEmpty() async {
        let (transport, bridge) = await connectedBridge(pausing: [ChatWire.typingIdle, ChatWire.typingRefresh])
        defer { bridge.connectionTask?.cancel() }
        bridge.userTypingChanged(true)
        bridge.userTypingChanged(true)
        await bridge.userTypingDelivery?.value
        bridge.userTypingChanged(false)
        bridge.userTypingChanged(false)
        await bridge.userTypingDelivery?.value
        #expect(transport.typingCalls == ["typing:true", "typing:false"])
    }

    /// Sinyal yang menunggu kiriman sebelumnya digabung menjadi yang terbaru, bukan diantre satu per satu.
    @Test
    func signalsWaitingForADeliveryAreCoalesced() async {
        let (transport, bridge) = await connectedBridge(pausing: [ChatWire.typingIdle, ChatWire.typingRefresh])
        defer { bridge.connectionTask?.cancel() }
        transport.isHoldingTyping = true
        bridge.userTypingChanged(true)
        await waitUntil { transport.isAckHeld }
        bridge.userTypingChanged(false)
        bridge.userTypingChanged(true)
        bridge.userTypingChanged(false)
        transport.releaseAck()
        await bridge.userTypingDelivery?.value
        #expect(transport.typingCalls == ["typing:true", "typing:false"])
    }

    /// Agen selesai selagi kiriman berjalan: sinyal yang menunggu dibuang, tidak dikirim ke bot.
    @Test
    func waitingSignalsAreDroppedWhenTheAgentLeaves() async {
        let (transport, bridge) = await connectedBridge(pausing: [ChatWire.typingIdle, ChatWire.typingRefresh])
        defer { bridge.connectionTask?.cancel() }
        transport.isHoldingTyping = true
        bridge.userTypingChanged(true)
        await waitUntil { transport.isAckHeld }
        bridge.userTypingChanged(false)
        transport.emit(WireFixture.stateFrame(seq: 3, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.conversationState == .assistantActive }
        transport.releaseAck()
        await bridge.userTypingDelivery?.value
        #expect(transport.typingCalls == ["typing:true"])
    }

    /// Init setelah putus bisa membawa state lain tanpa event `state`; status mengetik tetap dilupakan.
    @Test
    func reconnectingOutsideTheAgentForgetsTyping() async {
        let (transport, bridge) = await connectedBridge(pausing: [ChatWire.typingIdle, ChatWire.typingRefresh])
        defer { bridge.connectionTask?.cancel() }
        transport.initResults = [.success(WireFixture.initialize())]
        bridge.userTypingChanged(true)
        await bridge.userTypingDelivery?.value
        transport.drop()
        await waitUntil { bridge.conversationState == .assistantActive }
        #expect(!bridge.userTyping.isTyping)
        bridge.userTypingChanged(false)
        #expect(bridge.userTypingDelivery == nil)
    }

    /// Setelah sesi habis tidak ada lagi sinyal yang dikirim.
    @Test
    func expiredSessionSendsNoMoreTyping() async {
        let (transport, bridge) = await connectedBridge(pausing: [ChatWire.typingIdle, ChatWire.typingRefresh])
        defer { bridge.connectionTask?.cancel() }
        transport.typingError = TanyaAITransportError.response(
            statusCode: 401, body: WireFixture.error(isRetryable: false))
        bridge.userTypingChanged(true)
        await bridge.userTypingDelivery?.value
        bridge.userTypingChanged(true)
        bridge.userTypingChanged(false)
        await bridge.userTypingDelivery?.value
        #expect(bridge.connection == .expired)
        #expect(transport.typingCalls == ["typing:true"])
    }

    /// Sinyal hanya berarti bagi agen; saat dengan bot atau masih antre tidak dikirim.
    @Test(arguments: ["ASSISTANT_ACTIVE", "AGENT_QUEUED"])
    func typingOutsideTheAgentSessionIsNotSent(state: String) async {
        let (_, bridge) = await connectedBridge(state: state, pausing: [])
        defer { bridge.connectionTask?.cancel() }
        bridge.userTypingChanged(true)
        bridge.userTypingChanged(false)
        #expect(bridge.userTypingDelivery == nil)
    }

    /// Berhenti mengetik tanpa mengosongkan draft tetap dikabarkan setelah `typingIdle`.
    @Test
    func idleTypingStops() async {
        let (transport, bridge) = await connectedBridge(pausing: [ChatWire.typingRefresh])
        defer { bridge.connectionTask?.cancel() }
        bridge.userTypingChanged(true)
        await waitUntil { !bridge.userTyping.isTyping }
        await bridge.userTypingDelivery?.value
        #expect(transport.typingCalls == ["typing:true", "typing:false"])
    }

    /// Mengetik terus lebih lama dari `typingRefresh` mengirim `typing:true` lagi agar tidak kedaluwarsa di server.
    @Test
    func continuedTypingIsRefreshed() async {
        let (transport, bridge) = await connectedBridge(pausing: [ChatWire.typingIdle])
        defer { bridge.connectionTask?.cancel() }
        bridge.userTypingChanged(true)
        await bridge.userTypingDelivery?.value
        await waitUntil { bridge.userTypingRefresh == nil }
        bridge.userTypingChanged(true)
        await bridge.userTypingDelivery?.value
        #expect(transport.typingCalls == ["typing:true", "typing:true"])
    }

    /// Agen menutup percakapan: status mengetik dilupakan tanpa mengirim `typing:false` ke bot.
    @Test
    func leavingTheAgentForgetsTypingWithoutSending() async {
        let (transport, bridge) = await connectedBridge(pausing: [ChatWire.typingIdle, ChatWire.typingRefresh])
        defer { bridge.connectionTask?.cancel() }
        bridge.userTypingChanged(true)
        await bridge.userTypingDelivery?.value
        transport.emit(WireFixture.stateFrame(seq: 3, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.conversationState == .assistantActive }
        bridge.userTypingChanged(false)
        await bridge.userTypingDelivery?.value
        #expect(transport.typingCalls == ["typing:true"])
        #expect(!bridge.userTyping.isTyping)
    }

    /// Gagal kirim sinyal diabaikan; hanya 401 yang mengakhiri sesi.
    @Test(arguments: [(401, ChatConnection.expired), (500, .live), (410, .live)])
    func failedTypingOnlyExpiresOnUnauthorized(statusCode: Int, expected: ChatConnection) async {
        let (transport, bridge) = await connectedBridge(pausing: [ChatWire.typingIdle, ChatWire.typingRefresh])
        defer { bridge.connectionTask?.cancel() }
        transport.typingError = TanyaAITransportError.response(
            statusCode: statusCode, body: WireFixture.error(isRetryable: false))
        bridge.userTypingChanged(true)
        await bridge.userTypingDelivery?.value
        #expect(bridge.connection == expected)
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeUserTypingTests {
    /// `pausing` = jeda yang tertahan sampai test selesai. Jeda lain lewat setelah kiriman pertama tercatat, agar
    /// sinyal `true` tidak digabung dengan `false` sebelum sempat dikirim.
    func connectedBridge(
        state: String = "AGENT_ACTIVE", pausing: [TimeInterval]
    ) async -> (FakeChatTransport, TanyaAIBridge) {
        let transport = FakeChatTransport()
        transport.initResults = [.success(WireFixture.initialize(state: state))]
        let sleep: (TimeInterval) async throws -> Void = { seconds in
            guard pausing.contains(seconds) else {
                return await waitUntil { !transport.typingCalls.isEmpty }
            }
            try await Task.sleep(nanoseconds: 60_000_000_000)
        }
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: sleep)
        Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        return (transport, bridge)
    }
}
