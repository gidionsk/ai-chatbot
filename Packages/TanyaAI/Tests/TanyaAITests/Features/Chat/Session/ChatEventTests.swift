//
//  ChatEventTests.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import DesignKit
import Foundation
import Testing

@testable import TanyaAI

/// Decode event dari contoh swagger (`j1-plain-bot-turn`); frame rusak atau belum dipakai diabaikan.
struct ChatEventTests {
    @Test
    func messageFrameDecodesTheFullMessageObject() {
        let event = ChatEvent(frame(WireFixture.messageFrame(seq: 2, direction: "assistant")))
        let expected = ChatMessage(
            id: "m-2", seq: 2, author: .assistant, text: "pesan 2", status: .active, createdAt: WireFixture.createdAt
        )
        #expect(event == .message(expected))
    }

    /// `created_at` ISO 8601 dengan atau tanpa pecahan detik; format lain = tanpa tanggal.
    @Test
    func wireDatesKeepTheirTimeZoneWithOrWithoutFractions() {
        #expect(Date(wire: WireFixture.createdAtText) == WireFixture.createdAt)
        #expect(Date(wire: "2026-10-23T08:00:00.250Z") == WireFixture.createdAt.addingTimeInterval(0.25))
        #expect(Date(wire: "23-10-2026") == nil)
    }

    @Test(arguments: ["completed", "failed", "canceled"])
    func turnEndUnlocksRegardlessOfItsStatus(status: String) {
        #expect(ChatEvent(frame(WireFixture.turnEndFrame(seq: 3, status: status))) == .turnEnd(seq: 3))
    }

    /// `client_msg_id` pertanyaan nasabah dibawa untuk mencocokkan pertanyaan yang sedang ditunggu.
    @Test
    func userQuestionKeepsItsClientMessageID() {
        let event = ChatEvent(frame(WireFixture.messageFrame(seq: 1, clientMessageID: "c-1")))
        guard case let .message(message) = event else {
            Issue.record("frame pertanyaan harus menjadi pesan: \(event)")
            return
        }
        #expect(message.clientMessageID == "c-1")
    }

    @Test
    func canceledTombstoneKeepsItsStatus() {
        let event = ChatEvent(frame(WireFixture.messageFrame(seq: 1, status: "canceled")))
        let expected = ChatMessage(
            id: "m-1", seq: 1, author: .user, text: "pesan 1", status: .canceled, createdAt: WireFixture.createdAt
        )
        #expect(event == .message(expected))
    }

    /// Contoh §4 contract 1.5.0, termasuk pasangan bukti transaksi yang belum dipakai UI.
    @Test
    func contractMessageWithAReceiptDecodesAsAnAssistantAnswer() throws {
        let data = #"""
            {"message_id":"b3f1c2a0-4d6e-4a1b-9c2d-5e6f7a8b9c0d","seq":"1047","direction":"assistant",\#
            "type":"markdown","payload":"Halo **Lara**","intent":"portfolio-summary",\#
            "action":"buy_mutual_funds","source":"api-om","params":{},"success_id":"SUC-1",\#
            "success_at":"2026-10-20T09:05:00+07:00","follow_up_questions":["Lanjut?"],"interaction":null,\#
            "client_msg_id":null,"status":"active","created_at":"2026-10-20T09:00:00+07:00"}
            """#
        guard case .message(let message) = ChatEvent(ServerSentEvent(id: "1047", name: "message", data: data)) else {
            return #expect(Bool(false))
        }
        #expect(message.author == .assistant)
        #expect(message.document == MarkdownDocument("Halo **Lara**"))
        #expect(ChatRow.message(message).isVisible)
    }

    /// `type: text` tetap diproses sebagai Markdown; teks biasa tampil apa adanya.
    @Test
    func plainTextTypeStillBecomesAMarkdownDocument() throws {
        let event = ChatEvent(frame(WireFixture.messageFrame(seq: 2, direction: "assistant")))
        guard case .message(let message) = event else { return #expect(Bool(false)) }
        #expect(message.document == MarkdownDocument("pesan 2"))
    }

    @Test
    func assistantActiveStateIsAKnownState() throws {
        let data = WireFixture.initialize()
        #expect(try JSONDecoder.wire.decode(WireEnvelope<WireInit>.self, from: data).data.state == .assistantActive)
    }

    @Test
    func objectPayloadHasNoTextAndUnknownValuesDoNotFailTheFrame() {
        let data = #"{"message_id":"m-9","seq":"9","direction":"system","payload":{"k":1},"status":"new"}"#
        let event = ChatEvent(ServerSentEvent(id: "9", name: "message", data: data))
        #expect(event == .message(ChatMessage(id: "m-9", seq: 9, author: .unknown, text: nil, status: .unknown)))
    }

    @Test(arguments: [
        ServerSentEvent(id: "4", name: "message", data: "{rusak"),
        ServerSentEvent(
            id: "4", name: "message", data: #"{"message_id":"m","seq":"x","direction":"assistant","status":"active"}"#),
        ServerSentEvent(id: "5", name: "typing", data: #"{"direction":"agent","typing":true,"ttl_s":10}"#),
        ServerSentEvent(id: "6", name: "state", data: #"{"from":"ASSISTANT_ACTIVE","to":"CLOSED","agent":null}"#)
    ])
    func brokenOrUnusedFramesAreIgnored(event: ServerSentEvent) {
        #expect(ChatEvent(event) == .ignored)
    }
}

// MARK: - Helpers

private extension ChatEventTests {
    func frame(_ lines: [String]) -> ServerSentEvent {
        var parser = ServerSentEventParser()
        return lines.compactMap { parser.consume($0) }[0]
    }
}
