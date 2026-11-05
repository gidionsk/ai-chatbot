//
//  ChatListItemTests.swift
//  TanyaAITests
//
//  Created by Wendra on 5/11/26.
//

import DesignKit
import Foundation
import Testing

@testable import TanyaAI

struct ChatListItemTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func message(
        _ id: String, author: ChatAuthor = .assistant, text: String? = "Halo", day: Int = 1
    ) -> ChatRow {
        let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: day))
        return .message(ChatMessage(id: id, seq: .zero, author: author, text: text, status: .active, createdAt: date))
    }

    /// Diffable data source crash bila menerima id ganda, dan id pesan berasal dari server.
    @Test
    func duplicateIDsAppearOnce() {
        let items = [ChatListItem](rows: [message("a"), message("a"), message("b")], calendar: calendar)
        #expect(Set(items.map(\.id)).count == items.count)
        #expect(items.count == 3)
    }

    @Test
    func aDateChipPrecedesEachDay() {
        let items = [ChatListItem](rows: [message("a"), message("b", day: 2)], calendar: calendar)
        #expect(items.map(\.isQuestion) == [false, false, false, false])
        guard case .date = items[.zero], case .date = items[2] else {
            Issue.record("Chip tanggal hilang")
            return
        }
    }

    @Test
    func aMessageWithoutContentLeavesNoDateChip() {
        #expect([ChatListItem](rows: [message("a", text: nil)], calendar: calendar).isEmpty)
    }

    @Test
    func onlyTheFirstRowHasNoSpacing() {
        let items = [ChatListItem](rows: [message("a"), message("b")], calendar: calendar)
        #expect(items.first?.topSpacing == .zero)
        #expect(items.dropFirst().allSatisfy { $0.topSpacing == FigmaSize.spacingLarge.scaledToArtwork })
    }

    @Test
    func questionsAreRecognisedForParking() {
        let items = [ChatListItem](rows: [message("a", author: .user)], calendar: calendar)
        #expect(items.last?.isQuestion == true)
    }
}
