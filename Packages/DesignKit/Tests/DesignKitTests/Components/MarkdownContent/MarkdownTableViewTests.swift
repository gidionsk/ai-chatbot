//
//  MarkdownTableViewTests.swift
//  DesignKit
//
//  Created by Wendra on 4/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Tabel jawaban bot mengikuti Figma: lebar kolom sama dan baris ringkasan melewati kolom tengah.
@MainActor
struct MarkdownTableViewTests {
    private let header = "| Produk | Nilai | Untung |\n|:---|---:|---:|\n"

    @Test
    func rowWithOnlyItsOuterCellsFilledIsASummary() throws {
        let table = try table(from: header + "| Emas | 15.000.000 | +1.500.000 |\n| Total | | **+3.600.000** |")
        #expect(table.rows.map(table.isSummaryRow) == [false, true])
        #expect(!table.isSummaryRow(table.header))
    }

    @Test
    func missingLastCellAndTwoColumnsAreNotSummaries() throws {
        let partial = try table(from: header + "| Emas | | |")
        #expect(partial.rows.map(partial.isSummaryRow) == [false])
        let twoColumns = try table(from: "| Produk | Nilai |\n|---|---|\n| Emas | 15.000 |")
        #expect(twoColumns.rows.map(twoColumns.isSummaryRow) == [false])
    }

    /// Label yang tidak muat di sepertiga lebar tetap satu baris di baris ringkasan, tapi membungkus di baris biasa.
    @Test
    func summaryLabelUsesTheMiddleColumn() throws {
        try FontFace.registerFonts()
        let label = "Total Keuntungan Investasi"
        let summary = height(of: header + "| \(label) | | +3.600.000 |")
        let regular = height(of: header + "| \(label) | 1 | +3.600.000 |")
        #expect(summary < regular)
    }
}

// MARK: - Helpers

private extension MarkdownTableViewTests {
    func table(from markdown: String) throws -> MarkdownTable {
        guard case .table(let table) = try #require(MarkdownDocument(markdown).blocks.first) else {
            throw CocoaError(.coderInvalidValue)
        }
        return table
    }

    func height(of markdown: String) -> CGFloat {
        let content = MarkdownContent(document: MarkdownDocument(markdown), onOpenLink: { _ in })
        return UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: 240, height: 2_000)).height
    }
}
