//
//  StatusCaptionTests.swift
//  DesignKit
//
//  Created by Wendra on 19/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Ikon opsional: tanpa ikon teks langsung di tepi kiri, dengan ikon teks bergeser sebesar ikon dan jaraknya.
@MainActor
struct StatusCaptionTests {
    @Test
    func iconShiftsTheTextOnlyWhenItIsGiven() throws {
        try FontFace.registerFonts()
        let plain = idealWidth(of: StatusCaption(text: text))
        let withIcon = idealWidth(of: StatusCaption(text: text) { Color.clear })
        let shift = CustomSizes.StatusCaption.icon.scaledToArtwork + FigmaSize.spacingSmall.scaledToArtwork
        #expect(abs(withIcon - plain - shift) < tolerance)
    }

    @Test
    func captionFillsTheWidthOfItsContainer() throws {
        try FontFace.registerFonts()
        let size = UIHostingController(rootView: StatusCaption(text: text))
            .sizeThatFits(in: CGSize(width: width, height: 2_000))
        #expect(size.width == width)
    }
}

// MARK: - Helpers

private extension StatusCaptionTests {
    var text: String { "Mencari customer assistant..." }

    var width: CGFloat { 343 }

    /// Pembulatan layout ke piksel layar.
    var tolerance: CGFloat { 1 }

    func idealWidth(of content: some View) -> CGFloat {
        UIHostingController(rootView: content.fixedSize())
            .sizeThatFits(in: CGSize(width: width, height: 2_000)).width
    }
}
