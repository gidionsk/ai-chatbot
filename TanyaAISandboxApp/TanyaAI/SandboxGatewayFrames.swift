//
//  SandboxGatewayFrames.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 28/10/26.
//

import Foundation

/// Body dan baris SSE berbentuk contract chat-gateway 1.0.1 untuk gateway tiruan sandbox.
/// Menyimpan `seq` percakapan; setiap frame memakai nomor berikutnya.
struct SandboxGatewayFrames {
    static let conversationID = "sandbox-conversation"
    static let connected = ": connected"
    static let initialize = Data(
        #"{"success":true,"data":{"conversation_id":"sandbox-conversation","state":"BOT_ACTIVE"}}"#.utf8
    )
    static let emptyHistory = Data(#"{"success":true,"data":{"messages":[],"next_before":null}}"#.utf8)
    static let badRequest = Data(
        #"{"success":false,"error_code":"bad_request","data":null,"retryable":false,"request_id":"sandbox"}"#.utf8
    )
    static let badRequestStatus = 400
    /// Respons cancel: turn yang berjalan dihentikan / tidak ada turn aktif.
    static let canceled = Data(#"{"success":true,"data":{"canceled":true}}"#.utf8)
    static let nothingToCancel = Data(#"{"success":true,"data":{"canceled":false}}"#.utf8)
    static let canceledStatus = "canceled"
    static let completedStatus = "completed"
    /// Data dummy: jawaban bot mengulang pertanyaan.
    static func reply(to question: String) -> String { "Jawaban contoh untuk: \(question)" }

    /// `seq` terbesar di `TanyaAIHistoryDummy.json`; pesan baru melanjutkan setelahnya.
    static let historyLatestSeq = 4

    private var seq: Int

    init(seq: Int = 0) {
        self.seq = seq
    }

    mutating func ack() -> Data {
        Data(#"{"success":true,"data":{"message_id":"ack","seq":"\#(seq + 1)"}}"#.utf8)
    }

    /// Pesan baru dengan seq berikutnya; dikirim lewat `frame(_:)`.
    mutating func newMessage(direction: String, text: String, clientMessageID: String? = nil) -> SandboxWireMessage {
        seq += 1
        return SandboxWireMessage(
            messageId: UUID().uuidString, seq: String(seq), direction: direction, payload: text,
            status: SandboxWireMessage.active, clientMsgId: clientMessageID
        )
    }

    /// Frame `message`; `id:` = seq pesan.
    func frame(_ message: SandboxWireMessage) -> [String] {
        ["id: \(message.seq)", "event: message", "data: \(Self.json(message))", ""]
    }

    mutating func message(direction: String, text: String, clientMessageID: String? = nil) -> [String] {
        frame(newMessage(direction: direction, text: text, clientMessageID: clientMessageID))
    }

    /// Pertanyaan yang dihentikan dikirim ulang utuh dengan status `canceled`; `id:` frame memakai seq baru.
    mutating func tombstone(of question: SandboxWireMessage) -> [String] {
        seq += 1
        let canceled = SandboxWireMessage(
            messageId: question.messageId, seq: question.seq, direction: question.direction,
            payload: question.payload, status: SandboxWireMessage.canceled, clientMsgId: question.clientMsgId
        )
        return ["id: \(seq)", "event: message", "data: \(Self.json(canceled))", ""]
    }

    mutating func turnEnd(status: String = completedStatus) -> [String] {
        seq += 1
        return ["id: \(seq)", "event: turn_end", #"data: {"status":"\#(status)","active_turn_id":"sandbox"}"#, ""]
    }

    private static func json(_ message: SandboxWireMessage) -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return (try? encoder.encode(message)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }
}
