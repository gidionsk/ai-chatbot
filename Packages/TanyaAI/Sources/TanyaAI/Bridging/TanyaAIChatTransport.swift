//
//  TanyaAIChatTransport.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation

/// Jaringan ke chat-gateway Tanya AI, diimplementasikan host: base URL, header OMNI session/channel,
/// SSL pinning dan logging milik host. Setiap fungsi mengembalikan body mentah; TanyaAI yang men-decode,
/// mengatur urutan init → history → SSE, retry, dan merge.
///
/// Respons non-2xx dilempar sebagai `TanyaAITransportError.response` beserta body error envelope-nya.
/// Error lain (tidak ada koneksi, timeout) dilempar apa adanya dan dianggap bisa di-retry.
public protocol TanyaAIChatTransport: AnyObject {
    /// `POST /chat/init` dengan body `{}`: membuat atau melanjutkan percakapan milik CIF ini.
    func initialize() async throws -> Data

    /// `GET /chat/conversations/{id}/messages?limit=&before=`; `before` nil = halaman terbaru.
    func history(conversationID: String, before: String?, limit: Int) async throws -> Data

    /// `POST /chat/messages` dengan body `{conversation_id, client_msg_id, type: "text", payload}`.
    /// Ack 202 hanya tanda tersimpan; pesan tampil setelah datang lewat stream.
    func sendMessage(conversationID: String, clientMessageID: String, text: String) async throws -> Data

    /// `POST /chat/conversations/{id}/cancel` tanpa body: menghentikan jawaban yang sedang berjalan.
    /// Respons 200 `{canceled}`; kunci kirim tetap dibuka oleh `turn_end` di stream.
    func cancelTurn(conversationID: String) async throws -> Data

    /// `GET /chat/conversations/{id}/events` (`Accept: text/event-stream`), dengan header `Last-Event-ID`
    /// bila tidak nil. Kirim setiap baris teks apa adanya tanpa newline (baris kosong boleh dibuang,
    /// misalnya oleh `URLSession.AsyncBytes.lines`). Stream selesai saat koneksi ditutup server; error
    /// koneksi dilempar. Tutup request di `onTermination` karena TanyaAI membatalkan stream saat halaman ditutup.
    func events(conversationID: String, lastEventID: String?) -> AsyncThrowingStream<String, Error>
}
