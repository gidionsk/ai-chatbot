//
//  TanyaAIBridge+Connection.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation

extension TanyaAIBridge {
    /// Dijalankan `ChatScreen` lewat `.task` selama halaman tampil: init → history → SSE. Stream putus atau
    /// error yang bisa di-retry = jeda backoff lalu ulang dari init. Berhenti saat task dibatalkan (halaman
    /// ditutup), percakapan ditutup, sesi habis, atau error yang tidak bisa di-retry. Tiga yang terakhir final:
    /// `.task` yang jalan ulang saat halaman tampil lagi tidak menyambung, karena host sudah diberi tahu sekali.
    func run() async {
        // Task terpisah agar sesi habis (mis. 401 saat kirim) bisa menutup stream yang sedang terbuka.
        let task = Task { await connectUntilStopped() }
        connectionTask = task
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
    }
}

// MARK: - Connection

private extension TanyaAIBridge {
    func connectUntilStopped() async {
        var backoff = ChatBackoff()
        while !Task.isCancelled, !isConnectionFinal {
            let delay: TimeInterval
            do {
                guard try await connectOnce(onLive: { backoff.reset() }) else {
                    if connection != .expired {
                        connection = .closed
                    }
                    return
                }
                delay = backoff.nextDelay()
            } catch {
                guard !Task.isCancelled, let retryDelay = retryDelay(after: error, backoff: &backoff) else { return }
                delay = retryDelay
            }
            // Sesi habis atau halaman ditutup selama stream terbuka: status final tidak ditimpa.
            guard !Task.isCancelled, !isConnectionFinal else { return }
            connection = .connecting
            try? await sleep(delay)
        }
    }

    /// Sesi habis (401) atau ditutup (gagal permanen, percakapan `CLOSED`): tidak berubah selama bridge hidup.
    var isConnectionFinal: Bool { connection == .expired || connection == .closed }

    /// Satu siklus. False = percakapan `CLOSED` (history tetap dimuat, stream tidak dibuka).
    /// True = stream berakhir normal dan perlu disambung ulang.
    func connectOnce(onLive: () -> Void) async throws -> Bool {
        let session = try JSONDecoder.wire.decode(WireEnvelope<WireInit>.self, from: await transport.initialize()).data
        let isSameConversation = conversationID == nil || conversationID == session.conversationId
        let history = try await catchUpHistory(
            conversationID: session.conversationId, latestSeq: isSameConversation ? messages.latestSeq : nil
        )
        replaceOrMerge(history, conversationID: session.conversationId)
        conversationState = session.state
        guard session.state != .closed else { return false }
        // Replay mulai setelah pesan/event terakhir yang diterima: event di antara history dan stream tidak
        // hilang, duplikat pesan digabung lewat `message_id`, `turn_end` yang sudah diproses tidak diulang.
        let lines = transport.events(conversationID: session.conversationId, lastEventID: lastEventID)
        var parser = ServerSentEventParser()
        for try await line in lines {
            if connection == .connecting {
                connection = .live
                onLive()
            }
            if let event = parser.consume(line) {
                receive(event)
            }
        }
        return true
    }

    /// Cursor replay hanya dari event yang tersimpan di outbox. `id:` typing bisa saja berada di depan seq
    /// tersimpan terakhir; bila dipakai sebagai `Last-Event-ID`, server melewati pesan dengan seq tersebut.
    func receive(_ event: ServerSentEvent) {
        if event.name != ChatWire.Event.typing, let seq = event.id.flatMap(Int.init) {
            eventCursor = max(eventCursor ?? seq, seq)
        }
        apply(ChatEvent(event))
    }

    /// Halaman terbaru dulu, lalu halaman lebih lama sampai bertemu `latestSeq` yang sudah ada di daftar.
    /// Daftar kosong (pertama dibuka) cukup satu halaman; halaman lebih lama dimuat saat paging (TODO).
    func catchUpHistory(conversationID: String, latestSeq: Int?) async throws -> [ChatMessage] {
        var collected: [ChatMessage] = []
        var before: String?
        repeat {
            let data = try await transport.history(
                conversationID: conversationID, before: before, limit: ChatWire.historyPageSize
            )
            let page = try await ChatHistoryPage.decoded(from: data)
            collected += page.messages
            before = page.nextBefore
        } while before != nil && latestSeq.map { known in (collected.map(\.seq).min() ?? .min) > known } == true
        return collected
    }

    /// Nil = berhenti menyambung. 401 menyerahkan ke host; error lain yang `retryable:false` menutup percakapan
    /// dan diteruskan ke host lewat `onConnectionFailed`.
    func retryDelay(after error: Error, backoff: inout ChatBackoff) -> TimeInterval? {
        guard case let .response(statusCode, body)? = error as? TanyaAITransportError else {
            return backoff.nextDelay()
        }
        let failure = try? JSONDecoder.wire.decode(WireError.self, from: body)
        guard failure?.isRetryable ?? ChatBackoff.isServerError(statusCode: statusCode) else {
            if ChatBackoff.isUnauthorized(statusCode: statusCode) {
                expireSession()
            } else {
                failConnection(error)
            }
            return nil
        }
        return backoff.nextDelay(retryAfterMilliseconds: failure?.data?.retryAfterMs)
    }
}
