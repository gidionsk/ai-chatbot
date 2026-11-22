//
//  TypingDotsTests.swift
//  DesignKit
//
//  Created by Wendra on 19/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Ukuran tetap selama berdenyut: hanya opacity yang beranimasi, jadi baris table tidak berubah tinggi.
@MainActor
struct TypingDotsTests {
    @Test
    func dotsTakeOnlyTheirOwnSizeInARow() {
        let size = UIHostingController(rootView: TypingDots().fixedSize())
            .sizeThatFits(in: CGSize(width: 343, height: 2_000))
        let count = CGFloat(CustomMotion.typingDotDelays.count)
        let dot = CustomSizes.TypingDots.dot.scaledToArtwork
        let gaps = (count - 1) * FigmaSize.spacingSmall.scaledToArtwork
        #expect(abs(size.width - (count * dot + gaps)) < tolerance)
        #expect(abs(size.height - dot) < tolerance)
    }
}

// MARK: - Helpers

private extension TypingDotsTests {
    /// Pembulatan layout ke piksel layar.
    var tolerance: CGFloat { 1 }
}
