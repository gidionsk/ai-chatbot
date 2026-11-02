//
//  TanyaAIBridgeTests.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Kirim: bubble pertanyaan tampil saat itu juga, salinan dari stream menggantikannya, `turn_end` membuka kunci.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeTests {
    @Test
    func questionShowsAtOnceAndTheStreamCopyReplacesIt() async {
        let transport = FakeChatTransport()
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }

        let delivery = bridge.send("Cek Portfolio saya")
        #expect(bridge.localQuestions.map(\.text) == ["Cek Portfolio saya"], "tampil sebelum ack")
        #expect(bridge.isAwaitingReply)
        #expect(!bridge.isWelcomeVisible)
        #expect(bridge.send("Saya mau beli valas") == nil)
        await delivery?.value

        let question = WireFixture.messageFrame(
            seq: 1, direction: "customer", clientMessageID: transport.lastClientMessageID
        )
        transport.emit(question + WireFixture.messageFrame(seq: 2, direction: "bot"))
        await waitUntil { bridge.messages.count == 2 }
        #expect(bridge.localQuestions.isEmpty)
        #expect(bridge.rows.map(\.id) == ["m-1", "m-2"])
        #expect(bridge.isAwaitingReply)

        transport.emit(WireFixture.turnEndFrame(seq: 3))
        await waitUntil { !bridge.isAwaitingReply }
        #expect(transport.calls.filter { $0.hasPrefix("send") } == ["send:Cek Portfolio saya"])
    }

    /// Reconnect me-replay `turn_end` pertanyaan sebelumnya setelah pertanyaan baru dikirim: tetap terkunci.
    @Test
    func replayedTurnEndOfAnEarlierQuestionKeepsTheNewOneWaiting() async {
        let transport = FakeChatTransport()
        transport.sendResult = .success(WireFixture.ack(seq: 10))
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }
        #expect(await bridge.sendAndWait("Pertanyaan kedua"))
        transport.emit(WireFixture.turnEndFrame(seq: 6))
        transport.emit(WireFixture.messageFrame(seq: 10, direction: "customer"))
        await waitUntil { bridge.messages.count == 1 }
        #expect(bridge.isAwaitingReply)
        #expect(bridge.send("Pertanyaan ketiga") == nil)
        transport.emit(WireFixture.turnEndFrame(seq: 12))
        await waitUntil { !bridge.isAwaitingReply }
    }

    /// Stream lebih cepat dari respons HTTP: `turn_end` sebelum ack tetap membuka kunci setelah ack tiba.
    @Test
    func turnEndThatArrivesBeforeTheAckStillUnlocks() async {
        let transport = FakeChatTransport()
        transport.sendResult = .success(WireFixture.ack(seq: 10))
        transport.beforeAck = { transport.emit(WireFixture.turnEndFrame(seq: 12)) }
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }
        #expect(await bridge.sendAndWait("Cek Portfolio saya"))
        await waitUntil { !bridge.isAwaitingReply }
    }

    /// 401 saat kirim sama dengan 401 saat menyambung: host diberi tahu sekali, stream yang terbuka ditutup,
    /// tidak menyambung ulang, kirim berikutnya ditolak, dan pertanyaannya menjadi bubble gagal.
    @Test
    func unauthorizedSendClosesTheOpenStreamAndExpiresOnce() async {
        let transport = FakeChatTransport()
        transport.sendResult = .failure(
            TanyaAITransportError.response(statusCode: 401, body: WireFixture.error(isRetryable: false))
        )
        var expiredCount = 0
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: { expiredCount += 1 }, sleep: { _ in })
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }
        #expect(await bridge.sendAndWait("Cek Portfolio saya"))
        await waitUntil { transport.closedStreams == 1 }
        await task.value
        #expect(bridge.connection == .expired)
        #expect(bridge.localQuestions.map(\.isFailed) == [true])
        #expect(transport.calls.filter { $0 == "init" }.count == 1)
        #expect(bridge.send("Lagi") == nil)
        #expect(expiredCount == 1)
    }

    /// Respons kirim percakapan lama datang setelah reconnect ke percakapan lain dan kirim di sana:
    /// pertanyaan baru tidak berubah, jadi `turn_end` jawaban barunya tetap membuka kunci.
    @Test
    func lateSendResponseFromThePreviousConversationIsIgnored() async {
        let transport = FakeChatTransport()
        transport.initResults = [
            .success(WireFixture.initialize()), .success(WireFixture.initialize(conversationID: "lain"))
        ]
        transport.sendResult = .success(WireFixture.ack(seq: 10))
        transport.isHoldingAck = true
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }
        let lateSend = bridge.send("Pertanyaan lama")
        await waitUntil { transport.isAckHeld }
        transport.drop()
        await waitUntil { bridge.conversationID == "lain" && bridge.connection == .live }
        #expect(!bridge.isAwaitingReply)
        #expect(bridge.localQuestions.isEmpty, "bubble percakapan lama tidak ikut")
        transport.sendResult = .success(WireFixture.ack(seq: 2))
        let newSend = bridge.send("Pertanyaan baru")
        transport.releaseAck()
        await lateSend?.value
        await newSend?.value
        #expect(bridge.isAwaitingReply)
        #expect(bridge.localQuestions.map(\.text) == ["Pertanyaan baru"])
        transport.emit(WireFixture.turnEndFrame(seq: 3))
        await waitUntil { !bridge.isAwaitingReply }
    }

    /// Percakapan hilang saat kirim (404/410): sama dengan gagal permanen saat menyambung, host diberi tahu
    /// sekali, stream ditutup, dan tidak menyambung ulang.
    @Test(arguments: [404, 410])
    func sendToAGoneConversationStopsTheConnectionOnce(statusCode: Int) async {
        let transport = FakeChatTransport()
        let gone = TanyaAITransportError.response(statusCode: statusCode, body: WireFixture.error(isRetryable: false))
        transport.sendResult = .failure(gone)
        var failures = 0
        let bridge = TanyaAIBridge(
            transport: transport, onSessionExpired: nil, onConnectionFailed: { _ in failures += 1 }, sleep: { _ in }
        )
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }
        #expect(await bridge.sendAndWait("Cek Portfolio saya"))
        await waitUntil { transport.closedStreams == 1 }
        await task.value
        #expect(bridge.connection == .closed)
        #expect(bridge.localQuestions.map(\.isFailed) == [true])
        #expect(transport.calls.filter { $0 == "init" }.count == 1)
        #expect(failures == 1)
    }

    /// Gagal kirim lain (400, tanpa koneksi, 5xx): bubble gagal tanpa retry, kunci dibuka, sambungan tetap hidup.
    @Test(arguments: [
        TanyaAITransportError.response(statusCode: 400, body: Data()) as Error,
        URLError(.notConnectedToInternet)
    ])
    func failedSendLeavesAFailedBubbleAndUnlocks(error: Error) async {
        let transport = FakeChatTransport()
        transport.sendResult = .failure(error)
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.isReady }
        #expect(await bridge.sendAndWait("Cek Portfolio saya"))
        #expect(bridge.localQuestions.map(\.isFailed) == [true])
        #expect(!bridge.isAwaitingReply)
        #expect(bridge.isReady)
        transport.sendResult = .success(WireFixture.ack(seq: 2))
        #expect(await bridge.sendAndWait("Lagi"))
        #expect(bridge.localQuestions.map(\.isFailed) == [true, false])
    }

    @Test
    func sendBeforeTheConversationExistsIsRefusedWithoutCallingTheGateway() async {
        let transport = FakeChatTransport()
        let bridge = makeBridge(transport)
        #expect(bridge.send("Cek Portfolio saya") == nil)
        #expect(bridge.localQuestions.isEmpty)
        #expect(transport.calls.isEmpty)
    }

    /// Pesan pertama dari stream (mis. pertanyaan dari shortcut) langsung menggantikan sambutan.
    @Test
    func firstStreamedMessageHidesTheWelcome() async {
        let transport = FakeChatTransport()
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }
        #expect(bridge.isWelcomeVisible)
        transport.emit(WireFixture.messageFrame(seq: 1))
        await waitUntil { !bridge.isWelcomeVisible }
        #expect(bridge.messages.count == 1)
    }

    /// Halaman ditutup = task dibatalkan; stream ikut berakhir dan bridge tidak menyambung ulang.
    @Test
    func cancellingTheTaskStopsWithoutReconnecting() async {
        let transport = FakeChatTransport()
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        task.cancel()
        await task.value
        #expect(transport.calls.filter { $0 == "init" }.count == 1)
    }
}

// MARK: - Helpers

extension TanyaAIBridgeTests {
    func makeBridge(_ transport: FakeChatTransport) -> TanyaAIBridge {
        TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
    }
}
