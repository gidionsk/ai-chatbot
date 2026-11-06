//
//  ChatTableRefreshTests.swift
//  TanyaAITests
//
//  Created by Wendra on 6/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// Baris yang sudah tampil diperbarui hanya bila perlu: halaman berubah di tiap token stream.
@MainActor
struct ChatTableRefreshTests {
    private let rows = 60

    /// Tinggi baris kini mengikuti konten, jadi baris kosong bisa setinggi 0 dan tingginya ikut tersimpan.
    @Test
    func aRowWithoutContentKeepsTheConversationAtTheBottom() async {
        let fixture = ChatTableFixture()
        defer { fixture.close() }
        let items = ChatTableFixture.history(count: rows) + [.followUps([], isEnabled: true)]
        fixture.update(items: items, phase: .restored)
        await fixture.spin()
        fixture.update(items: items + [.content], phase: .restored)
        await fixture.spin()
        #expect(fixture.isRowVisible(rows - 1))
        #expect(fixture.controller.isNearBottom)
    }

    @Test
    func changedRowInputsRebuildTheVisibleRows() async {
        var builtCells = 0
        let fixture = ChatTableFixture(onBuild: { builtCells += 1 })
        defer { fixture.close() }
        fixture.update(items: ChatTableFixture.history(count: rows), phase: .restored)
        await fixture.spin()
        builtCells = 0
        fixture.update(rowInputs: ChatRowInputs(locale: Locale(identifier: "zh-Hans")))
        #expect(builtCells > 0)
    }

    /// Halaman berubah di tiap token stream, jadi menyegarkan konten sisipan tidak boleh membangun baris lain.
    @Test
    func refreshingInjectedContentRebuildsOnlyItsRow() async {
        var builtCells = 0
        let fixture = ChatTableFixture(onBuild: { builtCells += 1 })
        defer { fixture.close() }
        fixture.update(items: ChatTableFixture.history(count: rows) + [.content], phase: .restored)
        await fixture.spin()
        builtCells = 0
        fixture.controller.refreshInjectedContent()
        #expect(builtCells == 1)
    }

    @Test
    func refreshingSkipsInjectedContentOutsideTheScreen() async {
        var builtCells = 0
        let fixture = ChatTableFixture(onBuild: { builtCells += 1 })
        defer { fixture.close() }
        fixture.update(items: [.content] + ChatTableFixture.history(count: rows), phase: .restored)
        await fixture.spin()
        builtCells = 0
        fixture.controller.refreshInjectedContent()
        #expect(builtCells == 0)
    }
}
