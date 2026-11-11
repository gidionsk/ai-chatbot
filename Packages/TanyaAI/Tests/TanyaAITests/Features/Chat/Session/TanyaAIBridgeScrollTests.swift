//
//  TanyaAIBridgeScrollTests.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Nilai bridge yang menentukan posisi scroll daftar pesan.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeScrollTests {
    /// Bubble gagal yang tersisa tidak dianggap kiriman baru saat salinan pertanyaan berikutnya datang.
    @Test
    func deliveredQuestionKeepsTheLatestSentQuestion() async {
        let transport = FakeChatTransport()
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }

        transport.sendResult = .failure(URLError(.notConnectedToInternet))
        await bridge.send("gagal")?.value
        transport.sendResult = .success(WireFixture.ack(seq: 1))
        await bridge.send("berhasil")?.value
        let sentID = bridge.latestSentQuestionID
        #expect(sentID == transport.lastClientMessageID)

        transport.emit(WireFixture.messageFrame(seq: 1, direction: "user", clientMessageID: sentID))
        await waitUntil { bridge.messages.count == 1 }
        #expect(bridge.localQuestions.count == 1)
        #expect(bridge.latestSentQuestionID == sentID)
    }

    /// Pesan di luar turn diikuti daftar, termasuk pertanyaan dari kanal lain; jawaban turn sendiri tidak.
    @Test
    func onlyMessagesOutsideTheTurnCountAsIncoming() async {
        let transport = FakeChatTransport()
        transport.sendResult = .success(WireFixture.ack(seq: 2))
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }

        transport.emit(WireFixture.messageFrame(seq: 1, direction: "user"))
        await waitUntil { bridge.messages.count == 1 }
        #expect(bridge.latestIncomingMessageID == "m-1")

        await bridge.send("tanya")?.value
        transport.emit(WireFixture.messageFrame(seq: 3, direction: "assistant"))
        await waitUntil { bridge.messages.count == 2 }
        #expect(bridge.latestIncomingMessageID == "m-1")

        transport.emit(WireFixture.turnEndFrame(seq: 4) + WireFixture.messageFrame(seq: 5, direction: "assistant"))
        await waitUntil { bridge.messages.count == 3 }
        #expect(bridge.latestIncomingMessageID == "m-5")
    }

    /// Selama antre atau dengan agen tidak ada turn. Dulu salinan pertanyaan sendiri dari stream dihitung pesan
    /// masuk, jadi daftar ditarik ke bawah sebelum agen membalas.
    @Test
    func theCopyOfASentQuestionIsNotIncomingWhileWithAnAgent() async {
        let transport = FakeChatTransport()
        transport.initResults = [.success(WireFixture.initialize(state: "AGENT_ACTIVE"))]
        transport.sendResult = .success(WireFixture.ack(seq: 1))
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }

        await bridge.send("halo")?.value
        transport.emit(
            WireFixture.messageFrame(seq: 1, direction: "user", clientMessageID: bridge.latestSentQuestionID)
        )
        await waitUntil { bridge.messages.count == 1 }
        #expect(bridge.localQuestions.isEmpty)
        #expect(bridge.latestIncomingMessageID == nil)

        transport.emit(WireFixture.messageFrame(seq: 2, direction: "agent"))
        await waitUntil { bridge.messages.count == 2 }
        #expect(bridge.latestIncomingMessageID == "m-2")
    }

    /// Salinan tanpa `client_msg_id` dicocokkan lewat seq dari ack, dan tetap bukan pesan masuk.
    @Test
    func aCopyMatchedByItsSeqIsNotIncomingEither() async {
        let transport = FakeChatTransport()
        transport.initResults = [.success(WireFixture.initialize(state: "AGENT_QUEUED"))]
        transport.sendResult = .success(WireFixture.ack(seq: 1))
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }

        await bridge.send("halo")?.value
        transport.emit(WireFixture.messageFrame(seq: 1, direction: "user"))
        await waitUntil { bridge.messages.count == 1 }
        #expect(bridge.localQuestions.isEmpty)
        #expect(bridge.latestIncomingMessageID == nil)
    }

    /// Pertanyaan dari kanal lain bukan salinan kiriman halaman ini, jadi tetap diikuti.
    @Test
    func aQuestionFromAnotherChannelIsStillIncomingWhileWithAnAgent() async {
        let transport = FakeChatTransport()
        transport.initResults = [.success(WireFixture.initialize(state: "AGENT_ACTIVE"))]
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }

        transport.emit(WireFixture.messageFrame(seq: 1, direction: "user", clientMessageID: "kanal-lain"))
        await waitUntil { bridge.messages.count == 1 }
        #expect(bridge.latestIncomingMessageID == "m-1")
    }

    /// Daftar hanya dibuka di pesan terbaru bila history berisi pesan.
    @Test
    func historyPhaseFollowsWhatTheFirstLoadReturned() async {
        let empty = FakeChatTransport()
        let emptyBridge = makeBridge(empty)
        #expect(emptyBridge.historyPhase == .loading)
        let emptyTask = Task { await emptyBridge.run() }
        defer { emptyTask.cancel() }
        await waitUntil { emptyBridge.isHistoryLoaded }
        #expect(emptyBridge.historyPhase == .empty)

        let restored = FakeChatTransport()
        restored.historyPages = [WireFixture.history([2, 1])]
        let restoredBridge = makeBridge(restored)
        let restoredTask = Task { await restoredBridge.run() }
        defer { restoredTask.cancel() }
        await waitUntil { restoredBridge.isHistoryLoaded }
        #expect(restoredBridge.historyPhase == .restored)
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeScrollTests {
    func makeBridge(_ transport: FakeChatTransport) -> TanyaAIBridge {
        TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
    }
}
