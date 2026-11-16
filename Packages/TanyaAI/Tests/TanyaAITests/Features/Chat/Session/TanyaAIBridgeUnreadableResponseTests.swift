//
//  TanyaAIBridgeUnreadableResponseTests.swift
//  TanyaAI
//
//  Created by Wendra on 14/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Respons yang tidak bisa di-decode tidak diulang: host diberi tahu sekali dan loading berhenti.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeUnreadableResponseTests {
    @Test
    func anUnreadableInitStopsLoadingAndTellsTheHostOnce() async {
        let transport = FakeChatTransport()
        transport.initResults = [.success(Data("{}".utf8))]
        var failures: [Error] = []
        let bridge = makeBridge(transport) { failures.append($0) }
        await bridge.run()
        #expect(bridge.connection == .closed)
        #expect(!bridge.isLoadingHistory)
        #expect(failures.count == 1)
        #expect(failures.first is DecodingError)
        #expect(transport.calls == ["init"])
    }

    @Test
    func anUnreadableHistoryIsNotRetried() async {
        let transport = FakeChatTransport()
        transport.historyPages = [Data("bukan json".utf8)]
        var failures: [Error] = []
        let bridge = makeBridge(transport) { failures.append($0) }
        await bridge.run()
        #expect(bridge.connection == .closed)
        #expect(failures.count == 1)
        #expect(transport.calls.filter { $0 == "init" }.count == 1)
    }

    /// Koneksi putus tetap diulang seperti sebelumnya.
    @Test
    func aConnectionErrorIsStillRetried() async {
        let transport = FakeChatTransport()
        transport.initResults = [.failure(URLError(.notConnectedToInternet)), .success(WireFixture.initialize())]
        var failures: [Error] = []
        let bridge = makeBridge(transport) { failures.append($0) }
        let task = Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        task.cancel()
        #expect(failures.isEmpty)
        #expect(transport.calls.filter { $0 == "init" }.count == 2)
    }
}

// MARK: - Helpers

private extension TanyaAIBridgeUnreadableResponseTests {
    func makeBridge(_ transport: FakeChatTransport, onFailure: @escaping (Error) -> Void) -> TanyaAIBridge {
        TanyaAIBridge(transport: transport, onSessionExpired: nil, onConnectionFailed: onFailure, sleep: { _ in })
    }
}
