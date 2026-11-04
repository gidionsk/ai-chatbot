//
//  ChatEventTests.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Decode event dari contoh swagger (`j1-plain-bot-turn`); frame rusak atau belum dipakai diabaikan.
struct ChatEventTests {
    @Test
    func messageFrameDecodesTheFullMessageObject() {
        let event = ChatEvent(frame(WireFixture.messageFrame(seq: 2, direction: "bot")))
        let expected = ChatMessage(
            id: "m-2", seq: 2, author: .bot, text: "pesan 2", status: .active, createdAt: WireFixture.createdAt
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
    func customerQuestionKeepsItsClientMessageID() {
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
            id: "m-1", seq: 1, author: .customer, text: "pesan 1", status: .canceled, createdAt: WireFixture.createdAt
        )
        #expect(event == .message(expected))
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
            id: "4", name: "message", data: #"{"message_id":"m","seq":"x","direction":"bot","status":"active"}"#),
        ServerSentEvent(id: "5", name: "typing", data: #"{"direction":"agent","typing":true,"ttl_s":10}"#),
        ServerSentEvent(id: "6", name: "state", data: #"{"from":"BOT_ACTIVE","to":"CLOSED","agent":null}"#)
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
