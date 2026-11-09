//
//  TextChipTests.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Chip selebar teksnya ditambah padding; posisi di dalam daftar milik pemakai.
@MainActor
struct TextChipTests {
    @Test
    func chipHugsItsTextWithItsPadding() throws {
        try FontFace.registerFonts()
        let width: CGFloat = 375
        let chip = size(of: TextChip(text: "14 Okt 2026"), width: width)
        let text = size(
            of: Text("14 Okt 2026").font(
                FontFace.firaSansRegular.swiftUIFont(size: FigmaSize.typographySizeDisplayTiny12.scaledToArtwork)
            ),
            width: width
        )
        #expect(abs(chip.width - text.width - FigmaSize.spacingMedium.scaledToArtwork * 2) <= 0.5)
        #expect(abs(chip.height - text.height - FigmaSize.spacingSmall.scaledToArtwork * 2) <= 0.5)
    }
}

// MARK: - Helpers

private extension TextChipTests {
    func size(of content: some View, width: CGFloat) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: width, height: 800))
    }
}
