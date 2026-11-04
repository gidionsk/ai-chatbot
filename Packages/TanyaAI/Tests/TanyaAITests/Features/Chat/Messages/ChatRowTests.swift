//
//  ChatRowTests.swift
//  TanyaAI
//
//  Created by Wendra on 2/11/26.
//

import Testing

@testable import TanyaAI

/// Bubble lokal tetap di posisi saat dikirim dan dilepas saat salinan gateway-nya datang.
struct ChatRowTests {
    @Test
    func failedQuestionStaysWhereItWasSentAsLaterMessagesArrive() {
        let failed = LocalQuestion(id: "a", text: "gagal", afterSeq: 2, isFailed: true)
        let pending = LocalQuestion(id: "b", text: "baru", afterSeq: 2)
        let rows = messages([1, 2, 3, 4]).rows(with: [failed, pending])
        #expect(rows.map(\.id) == ["m-1", "m-2", "a", "b", "m-3", "m-4"])
    }

    @Test
    func questionsSentBeforeAnyMessageComeFirstOrLast() {
        let first = LocalQuestion(id: "a", text: "pertama", afterSeq: nil)
        #expect(messages([1]).rows(with: [first]).map(\.id) == ["a", "m-1"])
        let last = LocalQuestion(id: "b", text: "terakhir", afterSeq: 1)
        #expect(messages([1]).rows(with: [last]).map(\.id) == ["m-1", "b"])
    }

    /// Cocok lewat `client_msg_id` atau seq ack, hanya pesan nasabah setelah posisi kirimnya.
    @Test
    func deliveredMatchesTheCustomerCopyByClientIDOrAckSeq() {
        var question = LocalQuestion(id: "q", text: "Beli USD", afterSeq: 1)
        let bot = ChatMessage(id: "m-2", seq: 2, author: .assistant, text: "x", status: .active, clientMessageID: "q")
        let other = ChatMessage(id: "m-3", seq: 3, author: .user, text: "lain", status: .active)
        #expect(!question.isDelivered(in: [bot, other]))
        question.seq = 3
        #expect(question.isDelivered(in: [bot, other]))
        let copy = ChatMessage(
            id: "m-4", seq: 4, author: .user, text: "Beli USD", status: .active, clientMessageID: "q")
        #expect(LocalQuestion(id: "q", text: "Beli USD", afterSeq: 1).isDelivered(in: [copy]))
        let older = ChatMessage(
            id: "m-1", seq: 1, author: .user, text: "lama", status: .active, clientMessageID: "q")
        #expect(!LocalQuestion(id: "q", text: "Beli USD", afterSeq: 1).isDelivered(in: [older]))
    }
}

// MARK: - Helpers

private extension ChatRowTests {
    func messages(_ seqs: [Int]) -> [ChatMessage] {
        seqs.map { ChatMessage(id: "m-\($0)", seq: $0, author: .assistant, text: "pesan \($0)", status: .active) }
    }
}
