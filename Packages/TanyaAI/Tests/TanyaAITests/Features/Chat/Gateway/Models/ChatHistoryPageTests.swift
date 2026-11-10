//
//  ChatHistoryPageTests.swift
//  TanyaAITests
//
//  Created by Wendra on 4/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Halaman history dari wire menjadi pesan siap tampil, sudah termasuk dokumen Markdown jawaban bot.
struct ChatHistoryPageTests {
    @Test
    func pageKeepsItsMessagesAndCursor() async throws {
        let page = try await ChatHistoryPage.decoded(from: WireFixture.history([4, 3], nextBefore: "3"))
        #expect(page.messages.map(\.seq) == [4, 3])
        #expect(page.nextBefore == "3")
        #expect(page.messages.first?.document != nil)
        #expect(page.messages.last?.document == nil)
    }

    @Test
    func brokenBodyThrows() async {
        await #expect(throws: (any Error).self) {
            try await ChatHistoryPage.decoded(from: Data("bukan json".utf8))
        }
    }
}
