//
//  SandboxGatewayFrames.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 28/10/26.
//

import Foundation

/// Body dan baris SSE berbentuk contract chat-gateway 1.5.0 untuk gateway tiruan sandbox.
/// Menyimpan `seq` percakapan; setiap frame memakai nomor berikutnya.
struct SandboxGatewayFrames {
    static let conversationID = "sandbox-conversation"
    static let connected = ": connected"
    static let initialize = Data(
        #"{"success":true,"data":{"conversation_id":"sandbox-conversation","state":"ASSISTANT_ACTIVE"}}"#.utf8
    )
    static let emptyHistory = Data(#"{"success":true,"data":{"messages":[],"next_before":null}}"#.utf8)
    static let badRequest = Data(
        #"{"success":false,"error_code":"bad_request","data":null,"retryable":false,"request_id":"sandbox"}"#.utf8
    )
    static let badRequestStatus = 400
    /// Respons cancel: turn yang berjalan dihentikan / tidak ada turn aktif.
    static let canceled = Data(#"{"success":true,"data":{"canceled":true}}"#.utf8)
    static let nothingToCancel = Data(#"{"success":true,"data":{"canceled":false}}"#.utf8)
    /// Respons `leave-agent`: keluar dari antrean / tidak sedang antre.
    static let leftAgentQueue = Data(#"{"success":true,"data":{"left":true}}"#.utf8)
    static let notInAgentQueue = Data(#"{"success":true,"data":{"left":false}}"#.utf8)
    static let assistantActive = "ASSISTANT_ACTIVE"
    static let agentQueued = "AGENT_QUEUED"
    static let agentActive = "AGENT_ACTIVE"
    static let agentConnecting = "agent_connecting"
    static let agentJoined = "agent_joined"
    static let agentEnded = "agent_ended"
    static let backToAssistant = "back_to_assistant"
    static let queueCanceled = "queue_canceled"
    /// Data dummy `--live-agent`.
    static let handoverReply = "Baik, kami akan menghubungkan kamu ke live agent kami."
    static let agentGreeting = "Hi, saya Durenk, live agent yang akan membantu kamu."
    static let agentReply = "Baik, saya cek dulu ya."
    static let canceledStatus = "canceled"
    static let completedStatus = "completed"
    /// Data dummy: jawaban bot mengulang pertanyaan.
    /// Jawaban Markdown contoh: tebal, list, tabel, dan link (diteruskan ke host saat diketuk).
    static func reply(to question: String) -> String {
        """
        **Jawaban contoh** untuk: \(question)

        1. Kurs jual USD *Rp16.250*
        2. Kurs beli USD ~~Rp16.300~~ Rp16.100

        | Mata uang | Jual | Beli |
        |:---|---:|---:|
        | USD | 16.250 | 16.100 |

        Lihat [halaman kurs](https://www.ocbc.id/id/kurs).
        """
    }

    /// `seq` terbesar di `TanyaAIHistoryDummy.json`; pesan baru melanjutkan setelahnya.
    static let historyLatestSeq = 4
    /// Jumlah pesan `longHistory`, lebih panjang dari satu layar.
    static let longHistoryLatestSeq = 30
    private static let longAnswerSectionLimit = 4
    static let lateMessage = "Pesan baru tanpa pertanyaan"
    static let lateQuestion = "Pertanyaan dari kanal lain"
    static let longHistoryLastAnswer = "Jawaban terakhir history"
    /// Pesan selang-seling, terbaru dulu seperti gateway.
    static var longHistory: Data {
        let messages = (1...longHistoryLatestSeq).reversed().map(longHistoryMessage).joined(separator: ",")
        return Data(#"{"success":true,"data":{"messages":[\#(messages)],"next_before":null}}"#.utf8)
    }

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

    /// Frame `state` contract §5; nama agen hanya saat menuju `AGENT_ACTIVE`.
    mutating func state(_ state: String, previous: String) -> [String] {
        seq += 1
        let agent = state == Self.agentActive ? #"{"name":"Durenk"}"# : "null"
        let data = #"{"from":"\#(previous)","to":"\#(state)","agent":\#(agent)}"#
        return ["id: \(seq)", "event: state", "data: \(data)", ""]
    }

    /// Frame `system` contract §7.6.
    mutating func system(_ type: String) -> [String] {
        seq += 1
        return ["id: \(seq)", "event: system", #"data: {"type":"\#(type)","data":null}"#, ""]
    }

    /// Frame `typing` tidak tersimpan, jadi tidak memakai seq baru.
    func typing(isTyping: Bool) -> [String] {
        ["id: \(seq)", "event: typing", #"data: {"direction":"agent","typing":\#(isTyping),"ttl_s":10}"#, ""]
    }

    private static func longHistoryMessage(seq: Int) -> String {
        let isQuestion = seq.isMultiple(of: 2) == false
        let filler = isQuestion ? "Pertanyaan nomor \(seq)" : longAnswer(seq: seq)
        let payload = seq == longHistoryLatestSeq ? longHistoryLastAnswer : filler
        return json(
            SandboxWireMessage(
                messageId: "long-\(seq)", seq: String(seq),
                direction: isQuestion
                    ? SandboxWireMessage.user
                    : SandboxWireMessage.assistant,
                payload: payload, status: SandboxWireMessage.active, clientMsgId: nil
            ))
    }

    /// Tinggi berbeda-beda seperti jawaban asli: tinggi baris `LazyVStack` baru diketahui saat dibuat.
    private static func longAnswer(seq: Int) -> String {
        let section = """
            ### Bagian jawaban \(seq)

            | Produk | Nilai |
            |:---|---:|
            | Reksadana | 35.000.000 |
            | Obligasi | 30.000.000 |

            - Poin pertama yang cukup panjang supaya memakai beberapa baris di layar.
            - Poin kedua
            """
        return Array(repeating: section, count: seq % longAnswerSectionLimit + 1).joined(separator: "\n\n")
    }

    private static func json(_ message: SandboxWireMessage) -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return (try? encoder.encode(message)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }
}
