//
//  ChatMessageDocumentTests.swift
//  TanyaAITests
//
//  Created by Wendra on 3/11/26.
//

import DesignKit
import Testing

@testable import TanyaAI

/// Hanya jawaban bot yang dibaca sebagai Markdown; pesan tanpa tampilan tidak ikut daftar (dan chip tanggal).
struct ChatMessageDocumentTests {
    @Test
    func onlyBotTextIsParsedAsMarkdown() {
        #expect(message(.assistant, "**Kurs** USD").document == MarkdownDocument("**Kurs** USD"))
        #expect(message(.user, "**Kurs** USD").document == nil)
        #expect(message(.agent, "**Kurs** USD").document == nil)
        #expect(message(.assistant, nil).document == nil)
    }

    @Test
    func rowsWithoutAViewAreHidden() {
        #expect(ChatRow.message(message(.assistant, "jawaban")).isVisible)
        #expect(ChatRow.message(message(.agent, "agen")).isVisible)
        #expect(!ChatRow.message(message(.assistant, nil)).isVisible)
        #expect(!ChatRow.message(message(.unknown, "baru")).isVisible)
        #expect(ChatRow.local(LocalQuestion(id: "q", text: "tanya", afterSeq: nil)).isVisible)
    }
}

// MARK: - Helpers

private extension ChatMessageDocumentTests {
    func message(_ author: ChatAuthor, _ text: String?) -> ChatMessage {
        ChatMessage(id: "m-1", seq: 1, author: author, text: text, status: .active)
    }
}
