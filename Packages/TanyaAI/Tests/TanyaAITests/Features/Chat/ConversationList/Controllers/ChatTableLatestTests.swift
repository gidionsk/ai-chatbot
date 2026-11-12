//
//  ChatTableLatestTests.swift
//  TanyaAITests
//
//  Created by Wendra on 11/11/26.
//

import Foundation
import Testing
import UIKit

@testable import TanyaAI

/// Tombol ke pesan terbaru: kapan table melaporkan ujung daftar di luar layar, dan ke mana tombol membawa.
@MainActor
struct ChatTableLatestTests {
    private let rows = 60

    @Test
    func scrollingAwayHidesTheLatestAndTheJumpBringsItBack() async {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        var reports: [Bool] = []
        fixture.controller.onLatestVisibilityChange = { reports.append($0) }
        fixture.update(items: ChatTableFixture.history(count: rows), phase: .restored)
        await fixture.spin()
        fixture.table.scrollToRow(at: IndexPath(row: 10, section: .zero), at: .top, animated: false)
        fixture.table.layoutIfNeeded()
        fixture.controller.scrollViewDidScroll(fixture.table)
        fixture.controller.recordReadingPosition()
        await fixture.spin()
        #expect(reports == [false])
        fixture.jumpToLatest()
        await fixture.spin()
        #expect(reports == [false, true])
        #expect(abs(fixture.distanceToContentEnd) <= 1)
        #expect(fixture.isRowVisible(rows - 1))
    }

    /// History dibuka langsung di pesan terbaru; posisi teratas sebelum itu tidak boleh memunculkan tombol.
    @Test
    func openingAtTheLatestNeverReportsItHidden() async {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        var reports: [Bool] = []
        fixture.controller.onLatestVisibilityChange = { reports.append($0) }
        fixture.update(items: ChatTableFixture.history(count: rows), phase: .restored)
        await fixture.spin()
        #expect(reports.isEmpty)
    }

    /// Jawaban yang masih muat di bawah pertanyaan parkir sudah terlihat semua, jadi tidak ada yang perlu dikejar.
    @Test
    func aParkedQuestionWithAShortAnswerKeepsTheLatestVisible() async {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        var reports: [Bool] = []
        fixture.controller.onLatestVisibilityChange = { reports.append($0) }
        fixture.update(items: ChatTableFixture.history(count: 30), phase: .restored)
        fixture.update(items: ChatTableFixture.history(count: 31), phase: .restored, sentQuestionID: "m30")
        await fixture.spin()
        fixture.update(items: ChatTableFixture.history(count: 32), phase: .restored)
        await fixture.spin()
        #expect(fixture.controller.trailingInset > .zero)
        #expect(reports.isEmpty)
    }

    /// Jawaban melewati layar selama pertanyaan parkir: tombol muncul dan membawa ke ujung yang sebenarnya.
    @Test
    func theJumpLeavesAParkedQuestionForTheActualLatest() async {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        var reports: [Bool] = []
        fixture.controller.onLatestVisibilityChange = { reports.append($0) }
        fixture.update(items: ChatTableFixture.history(count: 30), phase: .restored)
        fixture.update(items: ChatTableFixture.history(count: 31), phase: .restored, sentQuestionID: "m30")
        await fixture.spin()
        fixture.update(items: ChatTableFixture.history(count: 31) + answers, phase: .restored)
        await fixture.spin()
        #expect(reports == [false])
        #expect(abs(fixture.contentTop(ofRow: 30) - fixture.controller.parkingOffset) <= 1)
        fixture.jumpToLatest()
        await fixture.spin()
        #expect(reports == [false, true])
        #expect(!fixture.controller.scrollMode.isQuestionParked)
        #expect(abs(fixture.distanceToContentEnd) <= 1)
        #expect(fixture.isRowVisible(33))
    }
}

// MARK: - Helpers

private extension ChatTableLatestTests {
    /// Tiga jawaban beruntun yang bersama-sama lebih tinggi dari layar; hanya `m30` yang pertanyaan.
    var answers: [ChatListItem] {
        [31, 33, 35].map { index in
            let message = ChatMessage(
                id: "m\(index)", seq: index, author: .assistant, text: "Jawaban \(index)", status: .active
            )
            return .message(.message(message), isSpaced: true)
        }
    }
}
