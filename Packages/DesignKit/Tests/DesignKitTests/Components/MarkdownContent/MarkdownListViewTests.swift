//
//  MarkdownListViewTests.swift
//  DesignKitTests
//
//  Created by Wendra on 4/11/26.
//

import SwiftUI
import Testing

@testable import DesignKit

/// Hanging indent: baris lanjutan item rata dengan teksnya, bukan dengan penanda.
@MainActor
struct MarkdownListViewTests {
    private let longText = String(repeating: "Kurs jual dan beli valas berubah setiap hari kerja. ", count: 6)

    /// Teks item memakai lebar setelah kolom penanda di semua baris: bila baris lanjutan kembali ke bawah
    /// penanda, tingginya akan berbeda dari paragraf selebar kolom teks.
    @Test
    func wrappedItemTextStaysInItsOwnColumn() throws {
        try FontFace.registerFonts()
        let width: CGFloat = 343
        let column = (CustomSizes.Markdown.listMarkerWidth + FigmaSize.spacingSmall).scaledToArtwork
        let item = height(of: "- \(longText)", width: width)
        #expect(abs(item - height(of: longText, width: width - column)) <= LayoutTolerance.measurement)
    }

    @Test
    func largestOrdinalSetsTheMarkerColumn() throws {
        let markdown = (1...10).map { "\($0). butir" }.joined(separator: "\n")
        guard case .list(let list) = try #require(MarkdownDocument(markdown).blocks.first) else {
            return #expect(Bool(false))
        }
        #expect(list.largestOrdinal == 10)
    }
}

// MARK: - Helpers

private extension MarkdownListViewTests {
    func height(of markdown: String, width: CGFloat) -> CGFloat {
        let content = MarkdownContent(document: MarkdownDocument(markdown), onOpenLink: { _ in })
        return UIHostingController(rootView: content)
            .sizeThatFits(in: CGSize(width: width, height: 2_000)).height
    }
}
