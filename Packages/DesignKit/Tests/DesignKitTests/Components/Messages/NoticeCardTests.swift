//
//  NoticeCardTests.swift
//  DesignKit
//
//  Created by Wendra on 10/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Kartu selebar wadah; isi yang lebih panjang turun ke baris berikutnya, bukan terpotong. Aksi menambah garis
/// pemisah dan aksinya sendiri di dalam kartu.
@MainActor
struct NoticeCardTests {
    @Test
    func cardFillsTheWidthAndGrowsWithItsMessage() throws {
        try FontFace.registerFonts()
        let short = size(of: card(message: "Antre."))
        let long = size(of: card(message: String(repeating: "Mohon kesediaannya untuk menunggu. ", count: 6)))
        #expect(short.width == width)
        #expect(long.width == width)
        #expect(long.height > short.height)
    }

    @Test
    func actionSitsBelowASeparatorInsideTheCard() throws {
        try FontFace.registerFonts()
        let plain = size(of: card(message: "Antre."))
        let withAction = size(
            of: NoticeCard(title: "Judul", message: "Antre.") {
                Color.clear
            } action: {
                Color.clear.frame(height: actionHeight)
            })
        let spacing = FigmaSize.spacingLarge.scaledToArtwork
        let separator = FigmaSize.weightOutline.scaledToArtwork
        #expect(withAction.width == width)
        #expect(abs(withAction.height - plain.height - (spacing * 2 + separator + actionHeight)) < tolerance)
    }
}

// MARK: - Helpers

private extension NoticeCardTests {
    var width: CGFloat { 343 }

    var actionHeight: CGFloat { 40 }

    /// Pembulatan layout ke piksel layar.
    var tolerance: CGFloat { 1 }

    func card(message: String) -> some View {
        NoticeCard(title: "Judul", message: message) { Color.clear }
    }

    func size(of content: some View) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: width, height: 2_000))
    }
}
