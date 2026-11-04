//
//  TanyaAIBridgeFollowUpTests.swift
//  TanyaAI
//
//  Created by Wendra on 4/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Saran lanjutan hanya dari jawaban terakhir; pilihan lama tidak ditawarkan lagi.
@MainActor
struct TanyaAIBridgeFollowUpTests {
    private let questions = #"["Bandingkan dengan pasar","Optimalkan investasi"]"#
    private let transport = FakeChatTransport()
    private let bridge: TanyaAIBridge

    init() {
        bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
    }

    @Test
    func latestAnswerOffersItsQuestionsInOrder() async {
        let task = await connect()
        defer { task.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 2, direction: "assistant", followUps: questions))
        await waitUntil { !bridge.followUps.isEmpty }
        #expect(bridge.followUps == ["Bandingkan dengan pasar", "Optimalkan investasi"])
    }

    /// Saat diketuk, saran hilang selama menunggu dan tidak kembali setelah jawaban baru tanpa saran.
    @Test
    func sendingHidesTheQuestionsAndANewAnswerReplacesThem() async {
        let task = await connect()
        defer { task.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 2, direction: "assistant", followUps: questions))
        await waitUntil { !bridge.followUps.isEmpty }

        transport.sendResult = .success(WireFixture.ack(seq: 3))
        await bridge.send("Bandingkan dengan pasar")?.value
        #expect(bridge.followUps.isEmpty)

        transport.emit(
            WireFixture.messageFrame(seq: 3, direction: "user", clientMessageID: transport.lastClientMessageID)
                + WireFixture.messageFrame(seq: 4, direction: "assistant") + WireFixture.turnEndFrame(seq: 5)
        )
        await waitUntil { !bridge.isAwaitingReply }
        #expect(bridge.followUps.isEmpty)
    }

    @Test
    func olderAnswerStopsOfferingOnceAQuestionFollowsIt() async {
        let task = await connect()
        defer { task.cancel() }
        transport.emit(
            WireFixture.messageFrame(seq: 2, direction: "assistant", followUps: questions)
                + WireFixture.messageFrame(seq: 3, direction: "user")
        )
        await waitUntil { bridge.messages.count == 2 }
        #expect(bridge.followUps.isEmpty)
    }

    /// Gagal kirim membuka kunci, jadi saran bisa diketuk lagi.
    @Test
    func failedSendBringsTheQuestionsBack() async {
        let task = await connect()
        defer { task.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 2, direction: "assistant", followUps: questions))
        await waitUntil { !bridge.followUps.isEmpty }

        transport.sendResult = .failure(URLError(.notConnectedToInternet))
        await bridge.send("Bandingkan dengan pasar")?.value
        #expect(bridge.followUps.count == 2)
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeFollowUpTests {
    func connect() async -> Task<Void, Never> {
        let task = Task { [bridge] in await bridge.run() }
        await waitUntil { bridge.isHistoryLoaded }
        transport.emit([": connected", ""])
        await waitUntil { bridge.connection == .live }
        return task
    }
}
