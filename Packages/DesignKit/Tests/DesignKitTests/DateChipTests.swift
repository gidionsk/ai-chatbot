//
//  DateChipTests.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Chip selebar daftar (teks di tengah) dengan padding vertikal kecil; satu baris.
@MainActor
struct DateChipTests {
    @Test
    func chipSpansTheRowAndAddsOnlyItsVerticalPadding() throws {
        try FontFace.registerFonts()
        let width: CGFloat = 375
        let chip = size(of: DateChip(text: "14 Okt 2026"), width: width)
        let text = size(
            of: Text("14 Okt 2026").font(
                FontFace.firaSansRegular.swiftUIFont(
                    size: FigmaSize.typographySizeDisplayTiny12.scaledToArtwork)), width: width)
        #expect(abs(chip.width - width) <= 0.5)
        #expect(abs(chip.height - text.height - FigmaSize.spacingSmall.scaledToArtwork * 2) <= 0.5)
    }
}

// MARK: - Helpers

private extension DateChipTests {
    func size(of content: some View, width: CGFloat) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: width, height: 800))
    }
}
