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

    /// Stop langsung sejak kirim; gagal = stop bisa ditekan lagi, `turn_end` = selesai.
    @Test
    func stopIsAvailableFromTheMomentOfSending() {
        var turn = ChatTurn()
        #expect(turn.phase == .idle)
        #expect(turn.startCanceling() == nil)
        turn.start(clientMessageID: "q")
        #expect(turn.phase == .awaitingReply)
        #expect(!turn.isAccepted)
        #expect(turn.startCanceling() == "q")
        #expect(turn.phase == .canceling)
        #expect(turn.isCanceling(clientMessageID: "q"))
        #expect(!turn.isCanceling(clientMessageID: "lama"))
        #expect(turn.startCanceling() == nil, "stop yang sedang diproses tidak dikirim dua kali")
        turn.accept(questionSeq: 2, for: "q")
        #expect(turn.isAccepted)
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
