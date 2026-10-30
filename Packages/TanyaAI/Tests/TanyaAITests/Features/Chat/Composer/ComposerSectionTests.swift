//
//  ComposerSectionTests.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import DesignKit
import SwiftUI
import Testing
import UIKit

@testable import TanyaAI

@MainActor
struct ComposerSectionTests {
    /// Divider selebar section di atas composer: menambah tepat satu garis outline. Padding composer 16 di
    /// semua sisi (Figma); di layar selain 375 nilai di-scale, jadi selisih padding tetap terdeteksi.
    @Test
    func dividerSpansTheSectionAboveTheComposerWithoutExtraSpacing() throws {
        try FontFace.registerFonts()
        let width: CGFloat = 375
        let inset = FigmaSize.spacingLarge.scaledToArtwork
        let section = measure(
            ComposerSection(isEnabled: true, phase: .idle, onSend: { _ in true }, onStop: {}), width: width)
        let composer = measure(
            MessageComposer(text: .constant(String()), placeholder: "Tanya", actionLabel: "Kirim", onSend: {}),
            width: width - inset * 2
        )
        let expected =
            composer.height + inset * 2 + FigmaSize.weightOutline.scaledToArtwork
        #expect(abs(section.width - width) <= 0.5)
        #expect(abs(section.height - expected) <= 0.5)
    }

    private func measure(_ content: some View, width: CGFloat) -> CGSize {
        let controller = UIHostingController(rootView: content)
        controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 800)
        controller.view.layoutIfNeeded()
        return controller.sizeThatFits(in: CGSize(width: width, height: 800))
    }
}
