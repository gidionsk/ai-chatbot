//
//  TanyaAIBridgeAgentExitTests.swift
//  TanyaAITests
//
//  Created by Wendra on 23/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Kartu selesai sesi agen di posisi event `state` yang keluar dari agen. Pesan nasabah selama sesi, termasuk yang
/// dikirim sebelum agen manusia bergabung, tetap di atas kartu, baik dari stream langsung, setelah `leave-agent`,
/// maupun saat event itu datang lewat replay setelah history dimuat.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeAgentExitTests {
    /// Urutan UAT: pesan nasabah, `state` AGENT_ACTIVE → ASSISTANT_ACTIVE, lalu `agent_left` yang tidak dikenal.
    @Test
    func userMessageDuringTheSessionStaysAboveTheEndedCard() async {
        let transport = FakeChatTransport()
        let bridge = await connectedBridge(transport, state: "AGENT_ACTIVE")
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        transport.emit(WireFixture.messageFrame(seq: 6, direction: "user"))
        transport.emit(WireFixture.stateFrame(seq: 7, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        transport.emit(WireFixture.systemFrame(seq: 8, type: "agent_left"))
        await waitUntil { bridge.eventCursor == 8 }
        #expect(itemIDs(bridge).suffix(3) == [.message("m-5"), .message("m-6"), .liveAgentNotice(7)])
    }

    /// `left:true` tiba sebelum event `state`: kartu sementara setelah pesan terakhir yang diterima, jadi pertanyaan ke
    /// bot yang dikirim sebelum event itu tetap di bawah kartu. Event `state` memindahkan kartu ke `seq` resminya.
    @Test
    func leavingKeepsTheEndedCardBetweenTheSessionAndTheNextQuestion() async {
        let transport = FakeChatTransport()
        transport.sendResult = .success(WireFixture.ack(seq: 8))
        let bridge = await connectedBridge(transport, state: "AGENT_ACTIVE")
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        transport.emit(WireFixture.messageFrame(seq: 6, direction: "user"))
        await waitUntil { bridge.messages.count == 4 }
        await bridge.leaveAgent(from: bridge.agentSessionKey)
        #expect(bridge.conversationState == .assistantActive)
        #expect(itemIDs(bridge).suffix(2) == [.message("m-6"), .liveAgentNotice(6)])

        await bridge.send("Halo")?.value
        let question = ChatListItemID.message(bridge.localQuestions.first?.id ?? "")
        #expect(contentIDs(bridge).suffix(3) == [.message("m-6"), .liveAgentNotice(6), question])

        transport.emit(WireFixture.stateFrame(seq: 7, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.eventCursor == 7 }
        #expect(bridge.agentExits.pending == nil)
        #expect(contentIDs(bridge).suffix(3) == [.message("m-6"), .liveAgentNotice(7), question])
    }

    /// History tidak membawa event `state`: kartu menebak dari pesan agen terakhir, lalu dipetakan ulang begitu event
    /// itu datang lewat replay stream.
    @Test
    func replayedStateEventRemapsTheHistoryCard() async {
        let transport = FakeChatTransport()
        let history = [
            WireFixture.message(seq: 11, direction: "user"), WireFixture.message(seq: 10, direction: "agent"),
            WireFixture.message(seq: 9, direction: "assistant")
        ]
        let bridge = await connectedBridge(transport, state: "ASSISTANT_ACTIVE", history: history)
        defer { bridge.connectionTask?.cancel() }
        #expect(itemIDs(bridge).suffix(3) == [.message("m-10"), .liveAgentNotice(10), .message("m-11")])

        transport.emit(WireFixture.stateFrame(seq: 12, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.eventCursor == 12 }
        #expect(itemIDs(bridge).suffix(3) == [.message("m-10"), .message("m-11"), .liveAgentNotice(12)])
    }

    /// Antrean baru yang dibatalkan tanpa jawaban bot setelah sesi sebelumnya selesai: kartu batal hanya menutup
    /// antrean itu, kartu selesai sesi sebelumnya tetap tampil.
    @Test
    func canceledNextQueueKeepsThePreviousEndedCard() async {
        let transport = FakeChatTransport()
        let bridge = await connectedBridge(transport, state: "AGENT_ACTIVE")
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        transport.emit(WireFixture.stateFrame(seq: 6, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        transport.emit(WireFixture.systemFrame(seq: 7, type: "agent_connecting"))
        transport.emit(WireFixture.stateFrame(seq: 8, state: "AGENT_QUEUED"))
        transport.emit(WireFixture.systemFrame(seq: 9, type: "queue_canceled"))
        transport.emit(WireFixture.stateFrame(seq: 10, state: "ASSISTANT_ACTIVE", previous: "AGENT_QUEUED"))
        await waitUntil { bridge.eventCursor == 10 }
        let cards = bridge.visibleLiveAgentNotices.filter { $0.kind != .connected }
        #expect(cards == [LiveAgentNotice(kind: .ended, seq: 6), LiveAgentNotice(kind: .canceled, seq: 9)])
    }

    /// Dibuka lagi saat `AGENT_ACTIVE` tanpa pesan agen dan tanpa `agent_joined` di replay: event keluar dari agen
    /// sendiri cukup untuk kartu selesai.
    @Test
    func servedSessionWithoutItsOpenerStillEnds() async {
        let transport = FakeChatTransport()
        let history = [WireFixture.message(seq: 10, direction: "user"), WireFixture.message(seq: 9)]
        let bridge = await connectedBridge(transport, state: "AGENT_ACTIVE", history: history)
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.stateFrame(seq: 11, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.eventCursor == 11 }
        #expect(itemIDs(bridge).suffix(2) == [.message("m-10"), .liveAgentNotice(11)])
    }

    /// Serah terima yang sesinya terbukti dilayani agen (keluar dari `AGENT_ACTIVE`) hanya mendapat kartu selesai,
    /// bukan juga kartu "tidak dilanjutkan".
    @Test
    func servedExitReplacesTheUnfinishedHandover() async {
        let transport = FakeChatTransport()
        let handover = WireFixture.message(seq: 9, direction: "assistant", intent: "handover-to-agent")
        let history = [WireFixture.message(seq: 10, direction: "user"), handover]
        let bridge = await connectedBridge(transport, state: "AGENT_ACTIVE", history: history)
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.stateFrame(seq: 11, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.eventCursor == 11 }
        #expect(bridge.visibleLiveAgentNotices == [LiveAgentNotice(kind: .ended, seq: 11)])
    }

    /// Pesan agen yang tiba setelah `left:true` tetapi sebelum event `state` masih milik sesi itu: kartu sementara
    /// bergeser ke bawahnya, bukan membuka sesi kedua dengan kartu selesai sendiri.
    @Test
    func agentMessageAfterLeavingStaysInTheSameSession() async {
        let transport = FakeChatTransport()
        let bridge = await connectedBridge(transport, state: "AGENT_ACTIVE")
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        await waitUntil { bridge.messages.count == 3 }
        await bridge.leaveAgent(from: bridge.agentSessionKey)
        transport.emit(WireFixture.messageFrame(seq: 6, direction: "agent"))
        await waitUntil { bridge.messages.count == 4 }
        #expect(itemIDs(bridge).suffix(3) == [.message("m-5"), .message("m-6"), .liveAgentNotice(6)])
    }

    /// Event keluar resmi terlewat (replay setelah reconnect dimulai sesudahnya) lalu antrean baru dimulai: posisi
    /// tunggu tetap menjadi akhir sesi lama, baik saat agen sudah menulis maupun belum.
    @Test(arguments: [true, false])
    func nextQueueKeepsThePendingEndOfTheSession(isAgentWriting: Bool) async {
        let transport = FakeChatTransport()
        let bridge = await connectedBridge(transport, state: "AGENT_ACTIVE")
        defer { bridge.connectionTask?.cancel() }
        let agentFrames = isAgentWriting ? [WireFixture.messageFrame(seq: 5, direction: "agent")] : []
        (agentFrames + [WireFixture.messageFrame(seq: 6, direction: "user")]).forEach(transport.emit)
        await waitUntil { bridge.eventCursor == 6 }
        await bridge.leaveAgent(from: bridge.agentSessionKey)
        transport.emit(WireFixture.stateFrame(seq: 8, state: "AGENT_QUEUED"))
        await waitUntil { bridge.eventCursor == 8 }
        let cards = bridge.visibleLiveAgentNotices.filter { $0.kind != .connected && $0.kind != .connecting }
        #expect(cards == [LiveAgentNotice(kind: .ended, seq: 6)])
    }

    /// Pesan ke agen yang sudah di-ack tetapi salinannya belum tiba saat End Session tetap di atas kartu sementara.
    @Test
    func acknowledgedQuestionStaysAboveThePendingCard() async {
        let transport = FakeChatTransport()
        transport.sendResult = .success(WireFixture.ack(seq: 6))
        let bridge = await connectedBridge(transport, state: "AGENT_ACTIVE")
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.messageFrame(seq: 5, direction: "agent"))
        await waitUntil { bridge.messages.count == 3 }
        await bridge.send("Halo")?.value
        let question = ChatListItemID.message(bridge.localQuestions.first?.id ?? "")
        await bridge.leaveAgent(from: bridge.agentSessionKey)
        #expect(contentIDs(bridge).suffix(3) == [.message("m-5"), question, .liveAgentNotice(6)])
    }

    /// Percakapan lain dari init membuang posisi akhir sesi percakapan lama.
    @Test
    func anotherConversationForgetsTheExits() async {
        let transport = FakeChatTransport()
        let bridge = await connectedBridge(transport, state: "AGENT_ACTIVE")
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.stateFrame(seq: 7, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.eventCursor == 7 }
        #expect(bridge.agentExits.marks == [.exit(seq: 7, isServed: true)])
        bridge.replaceOrMerge([], conversationID: "other")
        #expect(bridge.agentExits.marks.isEmpty)
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeAgentExitTests {
    /// Jeda (backoff, indikator mengetik) langsung selesai.
    func connectedBridge(
        _ transport: FakeChatTransport,
        state: String,
        history: [String]? = nil
    ) async -> TanyaAIBridge {
        transport.initResults = [.success(WireFixture.initialize(state: state))]
        transport.historyPages = [history.map { WireFixture.history(messages: $0) } ?? WireFixture.history([2, 1])]
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        return bridge
    }

    func itemIDs(_ bridge: TanyaAIBridge) -> [ChatListItemID] {
        [ChatListItem](rows: bridge.rows).inserting(bridge.visibleLiveAgentNotices, isLeaveEnabled: true).map(\.id)
    }

    /// Tanpa chip tanggal: pertanyaan baru memakai waktu perangkat, jadi bisa di hari lain dari fixture.
    func contentIDs(_ bridge: TanyaAIBridge) -> [ChatListItemID] {
        itemIDs(bridge).filter { id in
            guard case .date = id else { return true }
            return false
        }
    }
}
