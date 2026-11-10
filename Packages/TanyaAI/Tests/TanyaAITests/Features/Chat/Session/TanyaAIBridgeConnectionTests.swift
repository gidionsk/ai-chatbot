//
//  TanyaAIBridgeConnectionTests.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Urutan init → history → SSE, menyambung ulang dengan init + history baru, dan kapan berhenti.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeConnectionTests {
    @Test
    func openingLoadsHistoryThenStreamsAfterTheLatestSeq() async {
        let transport = FakeChatTransport()
        transport.historyPages = [WireFixture.history([2, 1])]
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }
        #expect(transport.calls == ["init", "history:latest", "events:2"])
        #expect(bridge.messages.map(\.seq) == [1, 2])
    }

    /// Loading sampai history pertama selesai; sambutan hanya untuk percakapan kosong.
    @Test(arguments: [[Int](), [2, 1]])
    func welcomeShowsOnlyAfterAnEmptyHistoryLoads(seqs: [Int]) async {
        let transport = FakeChatTransport()
        transport.historyPages = [WireFixture.history(seqs)]
        let bridge = makeBridge(transport)
        #expect(!bridge.isHistoryLoaded)
        #expect(!bridge.isWelcomeVisible)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.isHistoryLoaded }
        #expect(bridge.isWelcomeVisible == seqs.isEmpty)
    }

    /// Putus → init + history lagi; yang sudah ada tidak ditumpuk, sisanya ditambahkan, stream lanjut dari seq terbaru.
    @Test
    func reconnectMergesTheNewHistoryWithoutDuplicates() async {
        let transport = FakeChatTransport()
        transport.historyPages = [WireFixture.history([2, 1]), WireFixture.history([5, 4, 3, 2])]
        transport.scriptedStreams = [WireFixture.messageFrame(seq: 3)]
        var delays: [TimeInterval] = []
        let bridge = makeBridge(transport) { delays.append($0) }
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { transport.calls.last == "events:5" && bridge.connection == .live }
        #expect(bridge.messages.map(\.seq) == [1, 2, 3, 4, 5])
        #expect(transport.calls == ["init", "history:latest", "events:2", "init", "history:latest", "events:5"])
        #expect(delays == [1])
    }

    /// Cursor ikut `id` event terakhir (termasuk `turn_end`), jadi event yang sudah diproses tidak di-replay.
    @Test
    func reconnectResumesAfterTheLastEventNotJustTheLastMessage() async {
        let transport = FakeChatTransport()
        transport.historyPages = [WireFixture.history([1]), WireFixture.history([2, 1])]
        transport.scriptedStreams = [WireFixture.messageFrame(seq: 2) + WireFixture.turnEndFrame(seq: 3)]
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { transport.calls.count == 6 && bridge.connection == .live }
        #expect(transport.calls.filter { $0.hasPrefix("events") } == ["events:1", "events:3"])
    }

    /// `id:` typing tidak memajukan cursor: pesan dengan seq itu tetap di-replay setelah putus.
    @Test
    func typingIdDoesNotMoveTheReplayCursor() async {
        let transport = FakeChatTransport()
        transport.historyPages = [WireFixture.history([1]), WireFixture.history([1])]
        transport.scriptedStreams = [WireFixture.messageFrame(seq: 2) + WireFixture.typingFrame(seq: 3)]
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { transport.calls.count == 6 && bridge.connection == .live }
        #expect(transport.calls.filter { $0.hasPrefix("events") } == ["events:1", "events:2"])
    }

    /// Terlalu lama putus: halaman lebih lama diambil sampai bertemu pesan terakhir yang sudah ada.
    @Test
    func catchUpFetchesOlderPagesUntilItReachesTheKnownMessage() async {
        let transport = FakeChatTransport()
        transport.historyPages = [
            WireFixture.history([2, 1]), WireFixture.history([8, 7], nextBefore: "7"),
            WireFixture.history([6, 5], nextBefore: "5"), WireFixture.history([4, 3, 2], nextBefore: "2")
        ]
        transport.scriptedStreams = [[]]
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { transport.calls.last == "events:8" }
        #expect(
            transport.calls.filter { $0.hasPrefix("history") }.suffix(3) == ["history:latest", "history:7", "history:5"]
        )
        #expect(bridge.messages.map(\.seq) == Array(1...8))
    }

    @Test
    func unauthorizedStopsAndHandsOverToTheHostOnce() async {
        let transport = FakeChatTransport()
        transport.initResults = [.failure(response(401, WireFixture.error(isRetryable: false)))]
        var expiredCount = 0
        let bridge = TanyaAIBridge(
            transport: transport, onSessionExpired: { expiredCount += 1 }, sleep: { _ in }
        )
        await bridge.run()
        #expect(bridge.connection == .expired)
        #expect(!bridge.isLoadingHistory)
        #expect(expiredCount == 1)
        #expect(transport.calls == ["init"])
    }

    /// Error permanen saat pembukaan awal: loading berhenti (bukan spinner selamanya) dan host diberi tahu sekali.
    @Test
    func permanentFailureStopsLoadingAndTellsTheHostOnce() async {
        let transport = FakeChatTransport()
        transport.initResults = [.failure(response(403, WireFixture.error(isRetryable: false)))]
        var failedStatuses: [Int] = []
        let bridge = TanyaAIBridge(
            transport: transport, onSessionExpired: nil,
            onConnectionFailed: { error in
                if case let .response(statusCode, _)? = error as? TanyaAITransportError {
                    failedStatuses.append(statusCode)
                }
            },
            sleep: { _ in }
        )
        #expect(bridge.isLoadingHistory)
        await bridge.run()
        #expect(bridge.connection == .closed)
        #expect(!bridge.isLoadingHistory)
        #expect(!bridge.isWelcomeVisible)
        #expect(failedStatuses == [403])
        #expect(transport.calls == ["init"])
    }

    @Test
    func closedConversationShowsHistoryWithoutOpeningTheStream() async {
        let transport = FakeChatTransport()
        transport.initResults = [.success(WireFixture.initialize(state: "CLOSED"))]
        transport.historyPages = [WireFixture.history([2, 1])]
        let bridge = makeBridge(transport)
        await bridge.run()
        #expect(bridge.connection == .closed)
        #expect(bridge.messages.count == 2)
        #expect(transport.calls == ["init", "history:latest"])
    }

    @Test
    func capacityErrorWaitsAsLongAsTheServerAsksThenRetries() async {
        let transport = FakeChatTransport()
        transport.initResults = [
            .failure(response(503, WireFixture.error(isRetryable: true, retryAfterMs: 5_000))),
            .failure(URLError(.timedOut)), .success(WireFixture.initialize())
        ]
        var delays: [TimeInterval] = []
        let bridge = makeBridge(transport) { delays.append($0) }
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { bridge.connection == .live }
        #expect(delays == [5, 2])
    }

    /// Init mengembalikan percakapan lain (yang lama diarsipkan): daftar diganti, bukan digabung.
    @Test
    func differentConversationReplacesTheList() async {
        let transport = FakeChatTransport()
        transport.initResults = [
            .success(WireFixture.initialize()), .success(WireFixture.initialize(conversationID: "lain"))
        ]
        transport.historyPages = [WireFixture.history([2, 1]), WireFixture.history([1])]
        transport.scriptedStreams = [[]]
        let bridge = makeBridge(transport)
        let task = Task { await bridge.run() }
        defer { task.cancel() }
        await waitUntil { transport.calls.count == 6 && bridge.connection == .live }
        #expect(bridge.messages.map(\.seq) == [1])
        #expect(transport.calls.last == "events:1")
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeConnectionTests {
    func makeBridge(
        _ transport: FakeChatTransport, sleep: @escaping (TimeInterval) -> Void = { _ in }
    ) -> TanyaAIBridge {
        TanyaAIBridge(transport: transport, onSessionExpired: nil, sleep: { sleep($0) })
    }

    func response(_ statusCode: Int, _ body: Data) -> TanyaAITransportError {
        .response(statusCode: statusCode, body: body)
    }
}
