//
//  TanyaAIBridgeTurnTests.swift
//  TanyaAI
//
//  Created by Wendra on 30/10/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Fase composer: titik bergerak sampai pertanyaan datang dari stream, lalu stop sampai `turn_end`.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeTurnTests {
    @Test
    func sendingLastsUntilTheQuestionArrivesThenStopUntilTurnEnd() async {
        let (transport, bridge) = await connectedBridge()
        defer { bridge.connectionTask?.cancel() }
        #expect(await bridge.send("Cek Portfolio saya"))
        #expect(bridge.turnPhase == .sending)
        transport.emit(
            WireFixture.messageFrame(
                seq: 2, direction: "customer", clientMessageID: transport.lastClientMessageID
            ))
        await waitUntil { bridge.turnPhase == .awaitingReply }
        transport.emit(WireFixture.messageFrame(seq: 3, direction: "bot"))
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
        transport.emit(WireFixture.messageFrame(seq: 2, direction: "customer", status: "canceled"))
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

    /// Stop belum ada selama titik bergerak: tidak ada panggilan cancel ke gateway.
    @Test
    func stopBeforeTheQuestionIsShownDoesNothing() async {
        let (transport, bridge) = await connectedBridge()
        defer { bridge.connectionTask?.cancel() }
        #expect(await bridge.send("Cek Portfolio saya"))
        await bridge.cancelTurn()
        #expect(!transport.calls.contains("cancel"))
        #expect(bridge.turnPhase == .sending)
    }

    /// Stream putus sebelum pertanyaan datang: pertanyaan dari history setelah reconnect juga mengakhiri titik
    /// bergerak (dicocokkan lewat seq ack karena history tidak membawa `client_msg_id` di fixture ini).
    @Test
    func questionRecoveredFromHistoryAfterReconnectShowsStop() async {
        let transport = FakeChatTransport()
        transport.sendResult = .success(WireFixture.ack(seq: 3))
        transport.historyPages = [WireFixture.history([]), WireFixture.history([3])]
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        Task { await bridge.run() }
        defer { bridge.connectionTask?.cancel() }
        await waitUntil { bridge.connection == .live }
        #expect(await bridge.send("Cek Portfolio saya"))
        transport.drop()
        await waitUntil { bridge.turnPhase == .awaitingReply }
        #expect(bridge.messages.map(\.seq) == [3])
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeTurnTests {
    /// Sambungan hidup; test menghentikannya lewat `connectionTask` di akhir.
    func connectedBridge() async -> (FakeChatTransport, TanyaAIBridge) {
        let transport = FakeChatTransport()
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        return (transport, bridge)
    }

    /// Pertanyaan seq 2 sudah tampil dan jawaban belum selesai.
    func awaitingReplyBridge() async -> (FakeChatTransport, TanyaAIBridge) {
        let (transport, bridge) = await connectedBridge()
        _ = await bridge.send("Cek Portfolio saya")
        transport.emit(
            WireFixture.messageFrame(seq: 2, direction: "customer", clientMessageID: transport.lastClientMessageID)
        )
        await waitUntil { bridge.turnPhase == .awaitingReply }
        return (transport, bridge)
    }
}
