//
//  TanyaAIBridgeTurnTests.swift
//  TanyaAI
//
//  Created by Wendra on 30/10/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Fase composer: stop sejak kirim sampai `turn_end`.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeTurnTests {
    @Test
    func stopShowsFromTheMomentOfSendingUntilTurnEnd() async {
        let (transport, bridge) = await connectedBridge()
        defer { bridge.connectionTask?.cancel() }
        let delivery = bridge.send("Cek Portfolio saya")
        #expect(bridge.turnPhase == .awaitingReply, "tanpa menunggu ack atau stream")
        await delivery?.value
        transport.emit(
            WireFixture.messageFrame(
                seq: 2, direction: "user", clientMessageID: transport.lastClientMessageID
            ))
        transport.emit(WireFixture.messageFrame(seq: 3, direction: "assistant"))
        await waitUntil { bridge.messages.count == 2 }
        #expect(bridge.turnPhase == .awaitingReply)
        transport.emit(WireFixture.turnEndFrame(seq: 4))
        await waitUntil { bridge.turnPhase == .idle }
    }

    /// `canceled:true`: kunci tetap sampai `turn_end` canceled; tombstone pertanyaan menggantikan pesan aslinya.
    @Test
    func stopWaitsForTheCanceledTurnEnd() async {
        let (transport, bridge) = await awaitingReplyBridge()
        defer { bridge.connectionTask?.cancel() }
        await bridge.cancelTurn()
        #expect(transport.calls.filter { $0 == "cancel" }.count == 1)
        #expect(bridge.turnPhase == .canceling)
        await bridge.cancelTurn()
        #expect(transport.calls.filter { $0 == "cancel" }.count == 1, "stop yang diproses tidak dikirim lagi")
        transport.emit(WireFixture.messageFrame(seq: 2, direction: "user", status: "canceled"))
        transport.emit(WireFixture.turnEndFrame(seq: 3, status: "canceled"))
        await waitUntil { bridge.turnPhase == .idle }
        #expect(bridge.messages.map(\.status) == [.canceled])
    }

    /// `canceled:false`: gateway tidak punya turn aktif, jadi `turn_end` tidak akan datang; kunci dibuka langsung.
    @Test
    func stopWithNothingToCancelUnlocksAtOnce() async {
        let (transport, bridge) = await awaitingReplyBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.cancelResult = .success(WireFixture.cancel(isCanceled: false))
        await bridge.cancelTurn()
        #expect(bridge.turnPhase == .idle)
    }

    /// Cancel gagal (mis. 500) atau body tidak terbaca: stop bisa ditekan lagi, sambungan tetap hidup.
    @Test(arguments: [
        Result<Data, Error>.failure(TanyaAITransportError.response(statusCode: 500, body: Data())),
        .success(Data("{}".utf8))
    ])
    func failedStopCanBePressedAgain(result: Result<Data, Error>) async {
        let (transport, bridge) = await awaitingReplyBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.cancelResult = result
        await bridge.cancelTurn()
        #expect(bridge.turnPhase == .awaitingReply)
        #expect(bridge.connection == .live)
    }

    @Test
    func unauthorizedStopExpiresTheSession() async {
        let (transport, bridge) = await awaitingReplyBridge()
        defer { bridge.connectionTask?.cancel() }
        let unauthorized = TanyaAITransportError.response(statusCode: 401, body: WireFixture.error(isRetryable: false))
        transport.cancelResult = .failure(unauthorized)
        await bridge.cancelTurn()
        #expect(bridge.connection == .expired)
    }

    /// Stop sebelum ack: cancel ditahan lalu dikirim sekali saat ack tiba.
    @Test
    func stopBeforeTheAckIsSentOnceTheAckArrives() async {
        let (transport, bridge) = await connectedBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.isHoldingAck = true
        let delivery = bridge.send("Cek Portfolio saya")
        await waitUntil { transport.isAckHeld }
        await bridge.cancelTurn()
        #expect(!transport.calls.contains("cancel"))
        #expect(bridge.turnPhase == .canceling)
        transport.releaseAck()
        await delivery?.value
        #expect(transport.calls.filter { $0 == "cancel" }.count == 1)
        #expect(bridge.turnPhase == .canceling)
    }

    /// Stop sebelum ack lalu kirim gagal: tidak ada cancel, bubble gagal, kunci dibuka.
    @Test
    func stopBeforeAFailedSendDoesNotCallCancel() async {
        let (transport, bridge) = await connectedBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.isHoldingAck = true
        transport.sendResult = .failure(TanyaAITransportError.response(statusCode: 500, body: Data()))
        let delivery = bridge.send("Cek Portfolio saya")
        await waitUntil { transport.isAckHeld }
        await bridge.cancelTurn()
        transport.releaseAck()
        await delivery?.value
        #expect(!transport.calls.contains("cancel"))
        #expect(bridge.turnPhase == .idle)
        #expect(bridge.localQuestions.map(\.isFailed) == [true])
    }

    /// Stream putus sebelum pertanyaan datang: pertanyaan dari history setelah reconnect menggantikan bubble lokal
    /// (dicocokkan lewat seq ack karena history tidak membawa `client_msg_id` di fixture ini).
    @Test
    func questionRecoveredFromHistoryAfterReconnectReplacesTheLocalBubble() async {
        let transport = FakeChatTransport()
        transport.sendResult = .success(WireFixture.ack(seq: 3))
        transport.historyPages = [WireFixture.history([]), WireFixture.history([3])]
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        Task { await bridge.run() }
        defer { bridge.connectionTask?.cancel() }
        await waitUntil { bridge.connection == .live }
        #expect(await bridge.sendAndWait("Cek Portfolio saya"))
        #expect(bridge.localQuestions.count == 1)
        transport.drop()
        await waitUntil { bridge.messages.map(\.seq) == [3] }
        #expect(bridge.localQuestions.isEmpty)
        #expect(bridge.rows.map(\.id) == ["m-3"])
    }

    /// Init mengganti percakapan selagi kirim berjalan: 404/410 milik percakapan lama tidak menutup yang baru.
    @Test(arguments: [404, 410])
    func sendFailureForAReplacedConversationKeepsTheNewOne(statusCode: Int) async {
        let (transport, bridge) = await connectedBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.sendResult = .failure(
            TanyaAITransportError.response(statusCode: statusCode, body: WireFixture.error(isRetryable: false)))
        transport.isHoldingAck = true
        let delivery = bridge.send("Halo")
        await waitUntil { transport.isAckHeld }
        await replaceConversation(transport, bridge)
        transport.releaseAck()
        await delivery?.value
        #expect(bridge.connection == .live)
    }

    /// Sama untuk stop yang responsnya datang setelah percakapan berganti.
    @Test
    func stopFailureForAReplacedConversationKeepsTheNewOne() async {
        let (transport, bridge) = await awaitingReplyBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.cancelResult = .failure(
            TanyaAITransportError.response(statusCode: 410, body: WireFixture.error(isRetryable: false)))
        transport.isHoldingCancel = true
        let stop = Task { await bridge.cancelTurn() }
        await waitUntil { transport.isAckHeld }
        await replaceConversation(transport, bridge)
        transport.releaseAck()
        await stop.value
        #expect(bridge.connection == .live)
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeTurnTests {
    /// Stream putus lalu init memberi percakapan lain.
    func replaceConversation(_ transport: FakeChatTransport, _ bridge: TanyaAIBridge) async {
        transport.initResults = [.success(WireFixture.initialize(conversationID: "lain"))]
        transport.drop()
        await waitUntil { bridge.conversationID == "lain" && bridge.connection == .live }
    }

    /// Sambungan hidup; test menghentikannya lewat `connectionTask` di akhir.
    func connectedBridge() async -> (FakeChatTransport, TanyaAIBridge) {
        let transport = FakeChatTransport()
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        return (transport, bridge)
    }

    /// Pertanyaan seq 2 sudah datang dari stream dan jawaban belum selesai.
    func awaitingReplyBridge() async -> (FakeChatTransport, TanyaAIBridge) {
        let (transport, bridge) = await connectedBridge()
        _ = await bridge.sendAndWait("Cek Portfolio saya")
        transport.emit(
            WireFixture.messageFrame(seq: 2, direction: "user", clientMessageID: transport.lastClientMessageID)
        )
        await waitUntil { bridge.localQuestions.isEmpty }
        return (transport, bridge)
    }
}
