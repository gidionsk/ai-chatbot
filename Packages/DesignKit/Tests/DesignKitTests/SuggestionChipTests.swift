//
//  SuggestionChipTests.swift
//  DesignKitTests
//
//  Created by Wendra on 4/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Ukuran Figma: tinggi 40 dari ikon 24 + padding 8, lebar mengikuti isi, teks panjang turun baris.
@MainActor
struct SuggestionChipTests {
    private let leading = FigmaSize.spacingMedium.scaledToArtwork
    private let trailing = FigmaSize.spacingLarge.scaledToArtwork
    private let gap = FigmaSize.spacingSmall.scaledToArtwork
    private let iconSize = FigmaSize.weightIconSmall.scaledToArtwork

    @Test
    func chipHugsItsContent() throws {
        try FontFace.registerFonts()
        let text = "Bandingkan dengan pasar"
        let chip = size(of: SuggestionChip(text: text, onTap: {}), width: 375)
        #expect(abs(chip.width - (leading + iconSize + gap + textSize(text, width: 375).width + trailing)) <= 1)
        #expect(abs(chip.height - (iconSize + leading * 2)) <= 0.5)
    }

    @Test
    func longTextWrapsInsteadOfBeingCut() throws {
        try FontFace.registerFonts()
        let text = String(repeating: "Optimalkan investasi yang kurang produktif ", count: 3)
        let chip = size(of: SuggestionChip(text: text, onTap: {}), width: 240)
        #expect(chip.width <= 240.5)
        #expect(chip.height > iconSize + leading * 2)
    }
}

// MARK: - Helpers

private extension SuggestionChipTests {
    func textSize(_ text: String, width: CGFloat) -> CGSize {
        let font = FontFace.firaSansSemiBold.swiftUIFont(size: FigmaSize.typographySizeDisplayTiny12.scaledToArtwork)
        return size(of: Text(text).font(font), width: width)
    }

    func size(of content: some View, width: CGFloat) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: width, height: 800))
    }
}
