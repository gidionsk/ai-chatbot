//
//  SenderMessageCardTests.swift
//  DesignKit
//
//  Created by Wendra on 10/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Avatar di kiri tidak ikut membesar; teks panjang membuat kartu lebih tinggi, bukan lebih lebar.
@MainActor
struct SenderMessageCardTests {
    @Test
    func longTextWrapsInsideTheWidth() throws {
        try FontFace.registerFonts()
        let short = size(of: card(text: "Halo"))
        let long = size(of: card(text: String(repeating: "Saya cek dulu ya. ", count: 10)))
        #expect(short.width == width)
        #expect(long.width == width)
        #expect(long.height > short.height)
        #expect(short.height >= FigmaSize.weightIconSmall.scaledToArtwork)
    }
}

// MARK: - Helpers

private extension SenderMessageCardTests {
    var width: CGFloat { 343 }

    func card(text: String) -> some View {
        SenderMessageCard(sender: "Pengirim", text: text) { Color.clear }
    }

    func size(of content: some View) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: width, height: 2_000))
    }
}
