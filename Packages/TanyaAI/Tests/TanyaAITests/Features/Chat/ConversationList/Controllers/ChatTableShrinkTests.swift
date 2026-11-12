//
//  ChatTableShrinkTests.swift
//  TanyaAITests
//
//  Created by Wendra on 11/11/26.
//

import Testing
import UIKit

@testable import TanyaAI

/// Konten yang memendek dari bawah, mis. kartu antre hilang saat agen bergabung. Posisi baca lama tidak boleh
/// dipulihkan melewati ujung konten: animasi ikut ke bawah yang mulai dari sana melewati targetnya, jadi daftar
/// turun dulu lalu naik lagi.
@MainActor
struct ChatTableShrinkTests {
    private let rows = 40

    @Test
    func removingTheLastRowLeavesNoGapBelowTheContent() async {
        let fixture = ChatTableFixture(isReducingMotion: false)
        defer { fixture.close() }
        let items = ChatTableFixture.history(count: rows)
        fixture.update(items: items, phase: .restored)
        await fixture.spin()
        fixture.update(items: Array(items.dropLast()), phase: .restored)
        #expect(abs(fixture.distanceToContentEnd) <= 1)
        await fixture.spin()
        #expect(abs(fixture.distanceToContentEnd) <= 1)
        #expect(fixture.isRowVisible(rows - 2))
    }

    /// Seperti agen bergabung: kartu hilang dan pemicu ikut ke bawah berubah di update yang sama.
    @Test
    func followingAfterTheLastRowIsRemovedStartsInsideTheContent() async {
        let fixture = ChatTableFixture(isReducingMotion: false)
        defer { fixture.close() }
        var reports: [Bool] = []
        fixture.controller.onLatestVisibilityChange = { reports.append($0) }
        let items = ChatTableFixture.history(count: rows)
        fixture.update(items: items, phase: .restored, incomingMessageID: "m39")
        await fixture.spin()
        fixture.update(items: Array(items.dropLast()), phase: .restored, incomingMessageID: "m38")
        #expect(abs(fixture.distanceToContentEnd) <= 1)
        await fixture.spin()
        #expect(abs(fixture.distanceToContentEnd) <= 1)
        #expect(reports.isEmpty)
    }

    /// Pembaca yang sedang di atas tidak ikut dipindah saat baris terakhir hilang.
    @Test
    func removingTheLastRowLeavesAReaderOnTheirRow() async {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        let items = ChatTableFixture.history(count: rows)
        fixture.update(items: items, phase: .restored)
        await fixture.spin()
        fixture.table.scrollToRow(at: IndexPath(row: 10, section: .zero), at: .top, animated: false)
        fixture.table.layoutIfNeeded()
        fixture.controller.recordReadingPosition()
        let top = fixture.contentTop(ofRow: 10)
        fixture.update(items: Array(items.dropLast()), phase: .restored)
        await fixture.spin()
        #expect(abs(fixture.contentTop(ofRow: 10) - top) <= 1)
    }
}
