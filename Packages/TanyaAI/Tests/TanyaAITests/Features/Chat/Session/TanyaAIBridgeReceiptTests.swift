//
//  TanyaAIBridgeReceiptTests.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// `success-id` (contract §2.3a): pesan intent ditandai selesai setelah transaksinya berhasil.
@MainActor
@Suite(.serialized)
struct TanyaAIBridgeReceiptTests {
    /// Respons 200 langsung menandai pesan di tempatnya, tanpa menunggu frame dikirim ulang lewat stream.
    @Test
    func acceptedReceiptMarksTheMessageInPlace() async throws {
        let (transport, bridge) = await connectedBridge()
        defer { bridge.connectionTask?.cancel() }
        try await bridge.attachSuccessID("SUC-1", toMessageID: "m-2")
        #expect(transport.calls.contains("success:m-2:SUC-1"))
        #expect(bridge.messages.map(\.id) == ["m-1", "m-2", "m-3"])
        #expect(bridge.messages.map(\.successID) == [nil, "SUC-1", nil])
        #expect(bridge.messages[1].document != nil)
    }

    /// Gateway mengirim ulang frame dengan `seq` aslinya (lebih kecil dari pesan terakhir); pesan diganti, tidak
    /// ditambah dan tidak berpindah.
    @Test
    func reEmittedFrameReplacesTheMessage() async {
        let (transport, bridge) = await connectedBridge()
        defer { bridge.connectionTask?.cancel() }
        let receipt = WireFixture.message(seq: 2, successID: "SUC-1")
        transport.emit(["id: 2", "event: message", "data: \(receipt)", ""])
        await waitUntil { bridge.messages.contains { $0.successID != nil } }
        #expect(bridge.messages.map(\.id) == ["m-1", "m-2", "m-3"])
        #expect(bridge.messages[1].successID == "SUC-1")
    }

    @Test
    func unauthorizedReceiptExpiresTheSession() async {
        var expiredCount = 0
        let (transport, bridge) = await connectedBridge(onSessionExpired: { expiredCount += 1 })
        transport.successIDResult = .failure(
            TanyaAITransportError.response(statusCode: 401, body: WireFixture.error(isRetryable: false))
        )
        await #expect(throws: TanyaAITransportError.self) {
            try await bridge.attachSuccessID("SUC-1", toMessageID: "m-2")
        }
        #expect(bridge.connection == .expired)
        #expect(expiredCount == 1)
        #expect(bridge.messages.allSatisfy { $0.successID == nil })
    }

    /// 404 (pesan bukan milik nasabah/tanpa `action`), 409 (nilai berbeda sudah tercatat), atau 5xx: pemanggil yang
    /// memutuskan; percakapan tetap tersambung dan pesan tidak ditandai.
    @Test(arguments: [404, 409, 500])
    func otherFailuresKeepTheConversationOpen(statusCode: Int) async {
        var failures: [Error] = []
        let (transport, bridge) = await connectedBridge(onConnectionFailed: { failures.append($0) })
        defer { bridge.connectionTask?.cancel() }
        transport.successIDResult = .failure(
            TanyaAITransportError.response(statusCode: statusCode, body: WireFixture.error(isRetryable: false))
        )
        await #expect(throws: TanyaAITransportError.self) {
            try await bridge.attachSuccessID("SUC-1", toMessageID: "m-2")
        }
        #expect(bridge.connection == .live)
        #expect(failures.isEmpty)
        #expect(bridge.messages.allSatisfy { $0.successID == nil })
    }

    /// History berisi seq 1–3; seq 2 jawaban assistant.
    private func connectedBridge(
        onSessionExpired: (() -> Void)? = nil,
        onConnectionFailed: ((Error) -> Void)? = nil
    ) async -> (FakeChatTransport, TanyaAIBridge) {
        let transport = FakeChatTransport()
        transport.historyPages = [WireFixture.history([3, 2, 1])]
        let bridge = TanyaAIBridge(
            transport: transport,
            onSessionExpired: onSessionExpired,
            onConnectionFailed: onConnectionFailed,
            sleep: { _ in }
        )
        Task { await bridge.run() }
        await waitUntil { bridge.connection == .live }
        return (transport, bridge)
    }
}
