//
//  TanyaAIBridgeLiveAgentNoticeTests.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Kartu yang tampil dan indikator agen mengetik.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeLiveAgentNoticeTests {
    /// Kartu antre hanya selama antre; setelah agen bergabung kartu hilang, kartu penutup tetap.
    @Test
    func connectingCardOnlyShowsWhileQueued() async {
        let (transport, bridge) = await connectedBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_connecting"))
        transport.emit(WireFixture.stateFrame(seq: 4, state: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentQueued }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connecting, seq: 3)])
        transport.emit(WireFixture.stateFrame(seq: 5, state: "AGENT_ACTIVE", previous: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentActive }
        #expect(bridge.visibleLiveAgentNotices.isEmpty)
    }

    /// Kartu antre baru tampil setelah event `state`; pemicu ikut ke bawah harus berubah saat itu, bukan hanya saat
    /// event `system`-nya, agar tombol batal di bawah kartu tidak tertutup composer.
    @Test
    func followTriggerChangesWhenTheQueueCardAppears() async {
        let (transport, bridge) = await connectedBridge()
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_connecting"))
        await waitUntil { bridge.eventCursor == 3 }
        let beforeState = bridge.latestIncomingContentID
        transport.emit(WireFixture.stateFrame(seq: 4, state: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentQueued }
        #expect(bridge.latestIncomingContentID != beforeState)
    }

    /// Dibuka lagi saat masih antre tetapi event antre tidak ikut replay: kartu antre di akhir daftar.
    @Test
    func queuedConversationWithoutItsEventStillShowsTheCard() async {
        let (_, bridge) = await connectedBridge(state: "AGENT_QUEUED", history: [1, 2])
        defer { bridge.connectionTask?.cancel() }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connecting, seq: .max)])
    }

    /// History hanya membawa pesan: sesi agen yang sudah selesai diberi kartu selesai setelah pesan agen terakhir.
    @Test
    func finishedAgentSessionInHistoryGetsAnEndedCard() async {
        let (_, bridge) = await connectedBridge(history: [1, 2, 3])
        defer { bridge.connectionTask?.cancel() }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .ended, seq: 3)])
    }

    @Test
    func ongoingAgentSessionHasNoEndedCard() async {
        let (_, bridge) = await connectedBridge(state: "AGENT_ACTIVE", history: [1, 2, 3])
        defer { bridge.connectionTask?.cancel() }
        #expect(bridge.visibleLiveAgentNotices.isEmpty)
    }

    /// Sesi yang berakhir saat halaman terbuka memakai kartu dari stream, tidak ditambah kartu dari history.
    @Test
    func endedEventReplacesTheCardFromHistory() async {
        let (transport, bridge) = await connectedBridge(state: "AGENT_ACTIVE", history: [1, 2, 3])
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.systemFrame(seq: 4, type: "agent_ended"))
        transport.emit(WireFixture.stateFrame(seq: 5, state: "ASSISTANT_ACTIVE", previous: "AGENT_ACTIVE"))
        await waitUntil { bridge.conversationState == .assistantActive }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .ended, seq: 4)])
    }

    /// Dibuka lagi setelah serah terima yang tidak sampai ke agen: kartu "tidak dilanjutkan" setelah pesan itu.
    /// Selama masih antre yang tampil kartu antre.
    @Test(arguments: [
        ("ASSISTANT_ACTIVE", LiveAgentNotice(kind: .notContinued, seq: 2)),
        ("AGENT_QUEUED", LiveAgentNotice(kind: .connecting, seq: .max))
    ])
    func handoverInHistoryWithoutAnAgent(state: String, expected: LiveAgentNotice) async {
        let (_, bridge) = await connectedBridge(state: state, history: [1, 2], handover: 2)
        defer { bridge.connectionTask?.cancel() }
        #expect(bridge.visibleLiveAgentNotices == [expected])
    }

    /// Serah terima yang sedang berjalan tidak sempat menjadi kartu "tidak dilanjutkan" sebelum event antre tiba.
    @Test
    func liveHandoverIsNotMistakenForAnUnfinishedOne() async {
        let (transport, bridge) = await connectedBridge()
        defer { bridge.connectionTask?.cancel() }
        #expect(await bridge.sendAndWait("Saya mau agen"))
        let handover = WireFixture.message(seq: 4, intent: "handover-to-agent")
        transport.emit(["id: 4", "event: message", "data: \(handover)", ""])
        await waitUntil { bridge.messages.last?.intent == .liveAgent }
        #expect(bridge.visibleLiveAgentNotices.isEmpty)
        transport.emit(WireFixture.systemFrame(seq: 5, type: "agent_connecting"))
        transport.emit(WireFixture.stateFrame(seq: 6, state: "AGENT_QUEUED"))
        transport.emit(WireFixture.turnEndFrame(seq: 7))
        await waitUntil { bridge.turnPhase == .idle }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .connecting, seq: 5)])
    }

    /// Kartu antre yang sudah tersembunyi bukan penutup: antre selesai saat putus lalu bot menjawab lagi, kartu
    /// "tidak dilanjutkan" tetap dibuat dari history.
    @Test
    func staleQueueCardDoesNotHideTheUnfinishedHandover() async {
        let transport = FakeChatTransport()
        transport.initResults = [.success(WireFixture.initialize()), .success(WireFixture.initialize())]
        let first = [WireFixture.message(seq: 2, intent: "handover-to-agent"), WireFixture.message(seq: 1)]
        transport.historyPages = [
            WireFixture.history(messages: first), WireFixture.history(messages: [WireFixture.message(seq: 6)] + first)
        ]
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { _ in })
        Task { await bridge.run() }
        defer { bridge.connectionTask?.cancel() }
        await waitUntil { bridge.connection == .live }
        transport.emit(WireFixture.systemFrame(seq: 3, type: "agent_connecting"))
        transport.emit(WireFixture.stateFrame(seq: 4, state: "AGENT_QUEUED"))
        await waitUntil { bridge.conversationState == .agentQueued }
        transport.drop()
        await waitUntil { bridge.messages.count == 3 }
        #expect(bridge.visibleLiveAgentNotices == [.init(kind: .notContinued, seq: 2)])
    }

    /// Indikator hilang saat `typing:false` atau pesan agen datang.
    @Test
    func typingStopsWithTypingFalseOrTheAgentMessage() async {
        let (transport, bridge) = await connectedBridge(state: "AGENT_ACTIVE", isSleepReal: true)
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.typingFrame(seq: 3))
        await waitUntil { bridge.isAgentTyping }
        transport.emit(WireFixture.typingFrame(seq: 3, isTyping: false))
        await waitUntil { !bridge.isAgentTyping }
        transport.emit(WireFixture.typingFrame(seq: 3))
        await waitUntil { bridge.isAgentTyping }
        transport.emit(WireFixture.messageFrame(seq: 3, direction: "agent"))
        await waitUntil { !bridge.isAgentTyping }
    }

    /// Agen selesai saat putus: init membawa state bot tanpa event `state`, indikator tidak menunggu `ttl_s`.
    @Test
    func reconnectingOutsideTheAgentHidesTheTypingIndicator() async {
        let (transport, bridge) = await connectedBridge(state: "AGENT_ACTIVE", isSleepReal: true)
        defer { bridge.connectionTask?.cancel() }
        transport.initResults = [.success(WireFixture.initialize())]
        transport.emit(WireFixture.typingFrame(seq: 3))
        await waitUntil { bridge.isAgentTyping }
        transport.drop()
        await waitUntil { bridge.conversationState == .assistantActive }
        #expect(!bridge.isAgentTyping)
    }

    /// `typing:false` bisa hilang di jaringan; indikator dihapus sendiri setelah `ttl_s`.
    @Test
    func typingExpiresAfterItsLifetime() async {
        let (transport, bridge) = await connectedBridge(state: "AGENT_ACTIVE", isSleepReal: true)
        defer { bridge.connectionTask?.cancel() }
        transport.emit(WireFixture.typingFrame(seq: 3, lifetime: 1))
        await waitUntil { bridge.isAgentTyping }
        await waitUntil { !bridge.isAgentTyping }
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeLiveAgentNoticeTests {
    /// History seq 3 = pesan agen (seq 1 user, 2 bot); `handover` = seq bot ber-intent serah terima.
    /// `isSleepReal` untuk batas waktu indikator mengetik.
    func connectedBridge(
        state: String = "ASSISTANT_ACTIVE", history: [Int] = [], handover: Int? = nil, isSleepReal: Bool = false
    ) async -> (FakeChatTransport, TanyaAIBridge) {
        let transport = FakeChatTransport()
        transport.initResults = [.success(WireFixture.initialize(state: state))]
        let messages = history.reversed().map { seq in
            let intent = seq == handover ? ChatIntent.liveAgent.rawValue : ""
            return WireFixture.message(seq: seq, direction: seq == 3 ? "agent" : nil, intent: intent)
        }
        transport.historyPages = [WireFixture.history(messages: messages)]
        let sleep: (TimeInterval) async throws -> Void = { seconds in
            guard isSleepReal else { return }
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
        let bridge = TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: sleep)
        Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        return (transport, bridge)
    }
}
