//
//  FilledLinkButtonTests.swift
//  DesignKit
//
//  Created by Wendra on 10/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Tombol selebar wadah; tingginya teks ditambah padding atas dan bawah.
@MainActor
struct FilledLinkButtonTests {
    @Test
    func buttonFillsTheWidthWithItsPadding() throws {
        try FontFace.registerFonts()
        let width: CGFloat = 343
        let button = size(of: FilledLinkButton(title: "Batalkan proses ini") {}, width: width)
        let text = size(
            of: Text("Batalkan proses ini").font(
                FontFace.firaSansSemiBold.swiftUIFont(size: FigmaSize.typographySizeDisplayTiny12.scaledToArtwork)
            ),
            width: width
        )
        #expect(button.width == width)
        #expect(abs(button.height - text.height - FigmaSize.spacingMedium.scaledToArtwork * 2) <= 0.5)
    }
}

// MARK: - Helpers

private extension FilledLinkButtonTests {
    func size(of content: some View, width: CGFloat) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: width, height: 800))
    }
}
