//
//  WireFixture.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation

/// Body dan baris SSE berbentuk contoh di swagger chat-gateway 1.0.1.
enum WireFixture {
    static let conversationID = "30000000-0000-4000-8000-000000000001"
    static let createdAtText = "2026-10-23T15:00:00+07:00"
    /// 23 Oktober 2026 08:00 UTC.
    static let createdAt = Date(timeIntervalSince1970: 1_792_742_400)

    static func initialize(conversationID: String = conversationID, state: String = "BOT_ACTIVE") -> Data {
        Data(
            """
            {"success":true,"data":{"conversation_id":"\(conversationID)","state":"\(state)",\
            "message_id":null,"seq":null}}
            """.utf8)
    }

    /// `seqs` ditulis apa adanya; gateway mengirim terbaru dulu.
    static func history(_ seqs: [Int], nextBefore: String? = nil) -> Data {
        let messages = seqs.map { message(seq: $0) }.joined(separator: ",")
        let next = nextBefore.map { "\"\($0)\"" } ?? "null"
        return Data(#"{"success":true,"data":{"messages":[\#(messages)],"next_before":\#(next)}}"#.utf8)
    }

    static func cancel(isCanceled: Bool) -> Data {
        Data(#"{"success":true,"data":{"canceled":\#(isCanceled)}}"#.utf8)
    }

    static func ack(seq: Int = 2) -> Data {
        Data(#"{"success":true,"data":{"message_id":"b1b2c3d4-0002","seq":"\#(seq)"}}"#.utf8)
    }

    static func error(isRetryable: Bool, retryAfterMs: Int? = nil) -> Data {
        let data = retryAfterMs.map { #"{"retry_after_ms":\#($0)}"# } ?? "null"
        return Data(
            #"""
            {"success":false,"error_code":"x","message":"x","data":\#(data),"retryable":\#(isRetryable),\#
            "request_id":"req-1"}
            """#.utf8)
    }

    /// Objek `Message` lengkap; `direction` bot untuk seq genap, customer untuk ganjil kecuali ditentukan.
    static func message(
        seq: Int, direction: String? = nil, payload: String? = nil, status: String = "active",
        clientMessageID: String? = nil
    ) -> String {
        let author = direction ?? (seq.isMultiple(of: 2) ? "bot" : "customer")
        let clientID = clientMessageID.map { "\"\($0)\"" } ?? "null"
        return #"""
            {"message_id":"m-\#(seq)","seq":"\#(seq)","direction":"\#(author)","type":"text",\#
            "payload":"\#(payload ?? "pesan \(seq)")","intent":"","action":"","source":"","params":{},\#
            "follow_up_questions":null,"interaction":null,"client_msg_id":\#(clientID),"status":"\#(status)",\#
            "created_at":"2026-10-23T15:00:00+07:00"}
            """#
    }

    /// Frame SSE `message` lengkap dengan baris kosong penutup.
    static func messageFrame(
        seq: Int, direction: String? = nil, status: String = "active", clientMessageID: String? = nil
    ) -> [String] {
        let data = message(seq: seq, direction: direction, status: status, clientMessageID: clientMessageID)
        return ["id: \(seq)", "event: message", "data: \(data)", ""]
    }

    static func turnEndFrame(seq: Int, status: String = "completed") -> [String] {
        ["id: \(seq)", "event: turn_end", #"data: {"status":"\#(status)","active_turn_id":"100001"}"#, ""]
    }

    static func typingFrame(seq: Int) -> [String] {
        ["id: \(seq)", "event: typing", #"data: {"direction":"agent","typing":true,"ttl_s":10}"#, ""]
    }
}
