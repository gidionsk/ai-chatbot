//
//  ChatTurnTests.swift
//  TanyaAI
//
//  Created by Wendra on 29/10/26.
//

import Testing

@testable import TanyaAI

/// Hanya `turn_end` setelah seq pertanyaan yang ditunggu yang membuka kunci.
struct ChatTurnTests {
    @Test
    func oldTurnEndFromReplayKeepsWaiting() {
        var turn = ChatTurn()
        turn.start(clientMessageID: "q")
        turn.accept(questionSeq: 10, for: "q")
        turn.end(seq: 6)
        #expect(turn.isAwaiting)
        turn.end(seq: 12)
        #expect(!turn.isAwaiting)
    }

    @Test
    func turnEndBeforeTheAckIsMatchedWhenTheAckArrives() {
        var turn = ChatTurn()
        turn.start(clientMessageID: "q")
        turn.end(seq: 12)
        #expect(turn.isAwaiting)
        turn.accept(questionSeq: 10, for: "q")
        #expect(!turn.isAwaiting)
    }

    @Test
    func oldTurnEndBeforeTheAckDoesNotUnlock() {
        var turn = ChatTurn()
        turn.start(clientMessageID: "q")
        turn.end(seq: 6)
        turn.accept(questionSeq: 10, for: "q")
        #expect(turn.isAwaiting)
    }

    @Test
    func turnEndWithoutIdOrUnreadableAckStillUnlocks() {
        var withoutID = ChatTurn()
        withoutID.start(clientMessageID: "q")
        withoutID.accept(questionSeq: 10, for: "q")
        withoutID.end(seq: nil)
        #expect(!withoutID.isAwaiting)
        var unreadableAck = ChatTurn()
        unreadableAck.start(clientMessageID: "q")
        unreadableAck.accept(questionSeq: nil, for: "q")
        unreadableAck.end(seq: 3)
        #expect(!unreadableAck.isAwaiting)
    }

    /// Respons kirim pertanyaan lama (mis. sebelum percakapan berganti) tidak menyentuh pertanyaan baru.
    @Test
    func lateResponseOfAnEarlierQuestionIsIgnored() {
        var turn = ChatTurn()
        turn.start(clientMessageID: "lama")
        turn.start(clientMessageID: "baru")
        turn.accept(questionSeq: 2, for: "baru")
        turn.accept(questionSeq: 10, for: "lama")
        turn.cancel(clientMessageID: "lama")
        #expect(turn.isAwaiting)
        turn.end(seq: 3)
        #expect(!turn.isAwaiting)
    }

    /// Titik bergerak sampai pertanyaan tampil (lewat `client_msg_id` atau seq ack), lalu stop.
    @Test
    func questionFromTheStreamTurnsSendingIntoAwaitingReply() {
        var turn = ChatTurn()
        #expect(turn.phase == .idle)
        turn.start(clientMessageID: "q")
        #expect(turn.phase == .sending)
        let other = ChatMessage(id: "m-1", seq: 1, author: .customer, text: "lain", status: .active)
        let bot = ChatMessage(id: "m-3", seq: 3, author: .bot, text: "x", status: .active, clientMessageID: "q")
        #expect(!turn.isQuestionArriving(in: [other, bot]), "pesan bot atau pertanyaan lain tidak dihitung")
        let question = ChatMessage(
            id: "m-2", seq: 2, author: .customer, text: "q", status: .active, clientMessageID: "q")
        #expect(turn.isQuestionArriving(in: [other, question]))
        turn.showQuestion()
        #expect(turn.phase == .awaitingReply)
        #expect(!turn.isQuestionArriving(in: [other, question]), "sudah tampil: tidak diubah lagi")
    }

    @Test
    func questionWithoutClientIDIsMatchedByTheAckSeq() {
        var turn = ChatTurn()
        turn.start(clientMessageID: "q")
        let question = ChatMessage(id: "m-5", seq: 5, author: .customer, text: "q", status: .active)
        #expect(!turn.isQuestionArriving(in: [question]))
        turn.accept(questionSeq: 5, for: "q")
        #expect(turn.isQuestionArriving(in: [question]))
    }

    /// Stop hanya setelah pertanyaan tampil; gagal = stop bisa ditekan lagi, `turn_end` = selesai.
    @Test
    func stopIsOnlyAvailableOnceTheQuestionIsShown() {
        var turn = ChatTurn()
        turn.start(clientMessageID: "q")
        turn.accept(questionSeq: 2, for: "q")
        #expect(turn.startCanceling() == nil)
        turn.showQuestion()
        #expect(turn.startCanceling() == "q")
        #expect(turn.phase == .canceling)
        #expect(turn.startCanceling() == nil, "stop yang sedang diproses tidak dikirim dua kali")
        turn.stopCanceling(clientMessageID: "lama")
        #expect(turn.phase == .canceling)
        turn.stopCanceling(clientMessageID: "q")
        #expect(turn.phase == .awaitingReply)
        _ = turn.startCanceling()
        turn.end(seq: 4)
        #expect(turn.phase == .idle)
    }

    @Test
    func turnEndWhileIdleChangesNothing() {
        var turn = ChatTurn()
        turn.end(seq: 4)
        #expect(turn == ChatTurn())
    }
}
