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

/// Kartu selebar wadah; isi yang lebih panjang turun ke baris berikutnya, bukan terpotong.
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
}

// MARK: - Helpers

private extension NoticeCardTests {
    var width: CGFloat { 343 }

    func card(message: String) -> some View {
        NoticeCard(title: "Judul", message: message) { Color.clear }
    }

    func size(of content: some View) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: width, height: 2_000))
    }
}
