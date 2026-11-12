//
//  ChatTableBurstTests.swift
//  TanyaAITests
//
//  Created by Wendra on 12/11/26.
//

import Testing
import UIKit

@testable import TanyaAI

/// Beberapa pesan datang beruntun, mis. stream mengulang satu sesi agen tepat setelah halaman dibuka. Daftar harus
/// sampai di pesan terbaru tanpa merangkai animasi dan tanpa memunculkan tombol ke pesan terbaru. Window tanpa scene
/// tidak menjalankan animasi, jadi dengan `isReducingMotion` false animasi ikut ke bawah tetap "sedang berjalan".
@MainActor
@Suite(.serialized)
struct ChatTableBurstTests {
    private let rows = 30

    @Test
    func aMessageDuringTheFollowAnimationLandsAtTheLatestAtOnce() async {
        let fixture = await openedFixture()
        defer { fixture.close() }
        fixture.update(items: ChatTableFixture.history(count: rows + 2), phase: .restored, incomingMessageID: "m31")
        #expect(fixture.controller.scrollMode == .followingLatest)
        #expect(!fixture.controller.isNearBottom)
        fixture.update(items: ChatTableFixture.history(count: rows + 4), phase: .restored, incomingMessageID: "m33")
        #expect(abs(fixture.distanceToContentEnd) <= 1)
        #expect(fixture.isRowVisible(rows + 3))
        #expect(fixture.controller.scrollMode == .free)
    }

    @Test
    func followingTheLatestDoesNotReportItHidden() async {
        let fixture = await openedFixture()
        defer { fixture.close() }
        var reports: [Bool] = []
        fixture.controller.onLatestVisibilityChange = { reports.append($0) }
        fixture.update(items: ChatTableFixture.history(count: rows + 2), phase: .restored, incomingMessageID: "m31")
        await fixture.spin()
        #expect(fixture.controller.scrollMode == .followingLatest)
        #expect(reports.isEmpty)
    }

    /// Nasabah mengambil alih di tengah animasi: posisinya kini miliknya, jadi tombol muncul bila ujungnya jauh.
    @Test
    func takingOverDuringTheFollowAnimationReportsTheLatestHidden() async {
        let fixture = await openedFixture()
        defer { fixture.close() }
        var reports: [Bool] = []
        fixture.controller.onLatestVisibilityChange = { reports.append($0) }
        fixture.update(items: ChatTableFixture.history(count: rows + 2), phase: .restored, incomingMessageID: "m31")
        fixture.controller.scrollViewWillBeginDragging(fixture.table)
        fixture.controller.scrollViewDidScroll(fixture.table)
        await fixture.spin()
        #expect(reports == [false])
    }
}

// MARK: - Helpers

private extension ChatTableBurstTests {
    func openedFixture() async -> ChatTableFixture {
        let fixture = ChatTableFixture(isReducingMotion: false)
        fixture.update(items: ChatTableFixture.history(count: rows), phase: .restored)
        await fixture.spin()
        return fixture
    }
}
