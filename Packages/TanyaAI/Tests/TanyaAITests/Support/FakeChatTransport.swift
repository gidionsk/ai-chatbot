//
//  FakeChatTransport.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation

@testable import TanyaAI

/// Gateway tiruan. Init dan history diambil dari antrean (elemen terakhir dipakai ulang); setiap `events`
/// membuka stream baru yang diisi test lewat `emit`/`drop`, atau langsung dari `scriptedStreams`.
final class FakeChatTransport: TanyaAIChatTransport {
    var initResults: [Result<Data, Error>] = [.success(WireFixture.initialize())]
    var historyPages: [Data] = [WireFixture.history([])]
    /// Baris yang dikirim lalu stream ditutup dengan error koneksi; kosong = stream dibiarkan terbuka.
    var scriptedStreams: [[String]] = []
    var sendResult: Result<Data, Error> = .success(WireFixture.ack())
    var cancelResult: Result<Data, Error> = .success(WireFixture.cancel(isCanceled: true))
    /// `client_msg_id` kirim terakhir, untuk memancarkan pertanyaan yang sama dari stream.
    private(set) var lastClientMessageID: String?
    /// Dijalankan sebelum ack dikembalikan, mis. stream lebih cepat dari respons HTTP.
    var beforeAck: (() -> Void)?
    /// True = respons kirim berikutnya ditahan sampai `releaseAck()` (respons yang datang terlambat).
    var isHoldingAck = false
    private(set) var calls: [String] = []
    /// Jumlah stream yang sudah ditutup (putus, selesai, atau dibatalkan pemakai).
    private(set) var closedStreams = 0
    private var continuation: AsyncThrowingStream<String, Error>.Continuation?
    private var heldAck: CheckedContinuation<Void, Never>?

    var isAckHeld: Bool { heldAck != nil }

    func initialize() async throws -> Data {
        calls.append("init")
        return try next(&initResults).get()
    }

    func history(conversationID: String, before: String?, limit: Int) async throws -> Data {
        calls.append("history:\(before ?? "latest")")
        return next(&historyPages)
    }

    func sendMessage(conversationID: String, clientMessageID: String, text: String) async throws -> Data {
        calls.append("send:\(text)")
        lastClientMessageID = clientMessageID
        let result = sendResult
        beforeAck?()
        if isHoldingAck {
            isHoldingAck = false
            await withCheckedContinuation { heldAck = $0 }
        }
        return try result.get()
    }

    func cancelTurn(conversationID: String) async throws -> Data {
        calls.append("cancel")
        return try cancelResult.get()
    }

    func releaseAck() {
        heldAck?.resume()
        heldAck = nil
    }

    func events(conversationID: String, lastEventID: String?) -> AsyncThrowingStream<String, Error> {
        calls.append("events:\(lastEventID ?? "none")")
        return AsyncThrowingStream { continuation in
            continuation.onTermination = { _ in self.closedStreams += 1 }
            // Gateway selalu membuka stream dengan komentar `: connected`.
            continuation.yield(": connected")
            guard self.scriptedStreams.isEmpty else {
                self.scriptedStreams.removeFirst().forEach { continuation.yield($0) }
                continuation.finish(throwing: URLError(.networkConnectionLost))
                return
            }
            self.continuation = continuation
        }
    }

    /// Baris SSE ke stream yang sedang terbuka.
    func emit(_ lines: [String]) {
        lines.forEach { continuation?.yield($0) }
    }

    /// Koneksi putus di tengah stream.
    func drop() {
        continuation?.finish(throwing: URLError(.networkConnectionLost))
        continuation = nil
    }

    private func next<Element>(_ queue: inout [Element]) -> Element {
        queue.count > 1 ? queue.removeFirst() : queue[0]
    }
}
