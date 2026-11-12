//
//  ChatTableControllerTests.swift
//  TanyaAITests
//
//  Created by Wendra on 5/11/26.
//

import DesignKit
import Foundation
import Testing
import UIKit

@testable import TanyaAI

@MainActor
struct ChatTableControllerTests {
    private let rows = 60
    private let keyboardHeight: CGFloat = 240

    @Test
    func restoredHistoryOpensAtTheLatestRowInOneUpdate() {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        fixture.update(items: ChatTableFixture.history(count: rows), phase: .restored)
        #expect(fixture.isRowVisible(rows - 1))
        #expect(fixture.controller.isNearBottom)
    }

    @Test
    func anEmptyConversationStaysAtTheTop() {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        fixture.update(items: [], phase: .empty)
        fixture.update(items: ChatTableFixture.history(count: 1), phase: .empty)
        #expect(fixture.isRowVisible(.zero))
        #expect(abs(fixture.table.contentOffset.y + fixture.table.adjustedContentInset.top) <= 1)
    }

    /// Menerapkan snapshot tidak boleh membuang tinggi terukur: dulu ini memindahkan posisi ke baris lain.
    @Test
    func aNewMessageKeepsThePositionOfAReader() async {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        fixture.update(items: ChatTableFixture.history(count: rows), phase: .restored)
        fixture.table.scrollToRow(at: IndexPath(row: 40, section: .zero), at: .top, animated: false)
        fixture.table.layoutIfNeeded()
        fixture.controller.scrollViewDidScroll(fixture.table)
        fixture.controller.recordReadingPosition()
        let before = fixture.contentTop(ofRow: 40)
        fixture.update(
            items: ChatTableFixture.history(count: rows + 1), phase: .restored, incomingMessageID: "m\(rows)"
        )
        await fixture.spin()
        #expect(abs(fixture.contentTop(ofRow: 40) - before) <= 1)
        #expect(!fixture.isRowVisible(rows))
    }

    @Test
    func aNewMessageFollowsWhenAtTheBottom() async {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        fixture.update(items: ChatTableFixture.history(count: rows), phase: .restored)
        fixture.update(
            items: ChatTableFixture.history(count: rows + 1), phase: .restored, incomingMessageID: "m\(rows)"
        )
        await fixture.spin()
        #expect(fixture.isRowVisible(rows))
        #expect(fixture.controller.isNearBottom)
    }

    @Test
    func aSentQuestionParksBelowTheHeader() async {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        let history = ChatTableFixture.history(count: rows + 1)
        fixture.update(items: history, phase: .restored)
        fixture.update(items: ChatTableFixture.history(count: rows + 2), phase: .restored, sentQuestionID: "m\(rows)")
        await fixture.spin()
        #expect(abs(fixture.contentTop(ofRow: rows) - fixture.controller.parkingOffset) <= 1)
    }

    /// Konten lebih pendek dari layar: ruang kosong harus dihitung dari ujung konten, bukan dari posisi teratas.
    @Test
    func aShortConversationStillParksTheQuestion() async {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        fixture.update(items: ChatTableFixture.history(count: 3), phase: .restored)
        fixture.update(items: ChatTableFixture.history(count: 5), phase: .restored, sentQuestionID: "m4")
        await fixture.spin()
        #expect(fixture.controller.trailingInset > .zero)
        #expect(abs(fixture.contentTop(ofRow: 4) - fixture.controller.parkingOffset) <= 1)
    }

    @Test
    func theTrailingSpaceShrinksAsTheAnswerGrows() async {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        fixture.update(items: ChatTableFixture.history(count: 30), phase: .restored)
        fixture.update(items: ChatTableFixture.history(count: 31), phase: .restored, sentQuestionID: "m30")
        await fixture.spin()
        let empty = fixture.controller.trailingInset
        fixture.update(items: ChatTableFixture.history(count: 32), phase: .restored)
        await fixture.spin()
        #expect(fixture.controller.trailingInset < empty)
        #expect(abs(fixture.contentTop(ofRow: 30) - fixture.controller.parkingOffset) <= 1)
    }

    @Test
    func draggingReleasesTheParkedQuestion() {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        fixture.update(items: ChatTableFixture.history(count: 31), phase: .restored, sentQuestionID: "m30")
        fixture.controller.scrollViewWillBeginDragging(fixture.table)
        #expect(fixture.controller.scrollMode == .releasedQuestion)
    }

    @Test
    func reduceMotionMovesWithoutAnimation() {
        let moving = ChatTableFixture(isReducingMotion: false)
        let still = ChatTableFixture(isReducingMotion: true)
        defer {
            moving.close()
            still.close()
        }
        for fixture in [moving, still] {
            fixture.update(items: ChatTableFixture.history(count: 30), phase: .restored)
            fixture.update(items: ChatTableFixture.history(count: 31), phase: .restored, sentQuestionID: "m30")
        }
        #expect(moving.controller.isScrollAnimating)
        #expect(!still.controller.isScrollAnimating)
    }

    /// Dulu acuan posisi baca mengembalikan daftar ke posisi lama, jadi pesan terakhir tertutup keyboard.
    @Test
    func theKeyboardKeepsTheBottomOfTheConversationVisible() async {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        fixture.update(items: ChatTableFixture.history(count: rows), phase: .restored)
        await fixture.spin()
        await fixture.resize(height: ChatTableFixture.size.height - keyboardHeight)
        #expect(abs(fixture.distanceToContentEnd) <= 1)
        #expect(fixture.controller.isNearBottom)
        await fixture.resize(height: ChatTableFixture.size.height)
        #expect(abs(fixture.distanceToContentEnd) <= 1)
    }

    @Test
    func theKeyboardLeavesAReaderOnTheirRow() async {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        fixture.update(items: ChatTableFixture.history(count: rows), phase: .restored)
        fixture.table.scrollToRow(at: IndexPath(row: 40, section: .zero), at: .top, animated: false)
        fixture.table.layoutIfNeeded()
        fixture.controller.scrollViewDidScroll(fixture.table)
        fixture.controller.recordReadingPosition()
        let before = fixture.contentTop(ofRow: 40)
        await fixture.resize(height: ChatTableFixture.size.height - keyboardHeight)
        #expect(abs(fixture.contentTop(ofRow: 40) - before) <= 1)
    }

    @Test
    func theHeaderInsetFollowsAHeightThatChangesAfterTheFirstRender() {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        fixture.controller.updateHeaderHeight(ChatTableFixture.headerHeight + 22)
        let top = fixture.table.adjustedContentInset.top
        #expect(abs(top - (ChatTableFixture.headerHeight + 22 + FigmaSize.spacingLarge.scaledToArtwork)) <= 1)
        #expect(abs(fixture.table.contentOffset.y + top) <= 1)
    }

    @Test
    func scrollingReportsProgressForTheHeader() async {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        var progress = CGFloat.zero
        fixture.controller.onScrollProgress = { progress = $0 }
        fixture.update(items: ChatTableFixture.history(count: rows), phase: .restored)
        await waitUntil { progress == 1 }
    }

    /// Daftar panjang hanya membuat sel yang tampil; ini yang membedakannya dari `VStack`.
    @Test
    func aLongConversationOnlyBuildsTheVisibleRows() async {
        var builtCells = 0
        let fixture = ChatTableFixture(onBuild: { builtCells += 1 })
        defer { fixture.close() }
        fixture.update(items: ChatTableFixture.history(count: 500), phase: .restored)
        await fixture.spin()
        #expect(builtCells < 60)
    }

    @Test
    func theControllerIsReleasedWithItsPage() async {
        weak var released: ChatTableController?
        autoreleasepool {
            let fixture = ChatTableFixture()
            fixture.update(items: ChatTableFixture.history(count: rows), phase: .restored)
            released = fixture.controller
            fixture.close()
        }
        // Blok yang masih antre memegang controller secara weak, jadi tidak boleh menahannya.
        await Task.yield()
        #expect(released == nil)
    }
}
