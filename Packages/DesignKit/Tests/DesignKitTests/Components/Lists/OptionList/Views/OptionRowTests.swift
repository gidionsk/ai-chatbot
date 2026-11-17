//
//  OptionRowTests.swift
//  DesignKitTests
//
//  Created by Wendra on 17/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

@MainActor
struct OptionRowTests {
    private let width: CGFloat = 375

    @Test(arguments: [false, true])
    func aSubtitleAddsHeightWithoutChangingTheRowWidth(isSelected: Bool) throws {
        try FontFace.registerFonts()
        let plain = size(of: row(subtitle: nil, isSelected: isSelected))
        let detailed = size(of: row(subtitle: "Sample balance", isSelected: isSelected))
        #expect(detailed.height > plain.height)
        #expect(detailed.width == plain.width)
    }

    @Test(arguments: [false, true])
    func aRowWithoutASubtitleKeepsItsPreviousAppearance(isSelected: Bool) throws {
        try FontFace.registerFonts()
        let previous = legacyRow(isSelected: isSelected)
        let current = row(subtitle: nil, isSelected: isSelected)
        #expect(size(of: current) == size(of: previous))
        let expected = try #require(RenderedImage.png(of: previous, width: width))
        #expect(RenderedImage.png(of: current, width: width) == expected)
    }
}

// MARK: - Helpers

private extension OptionRowTests {
    func row(subtitle: String?, isSelected: Bool) -> some View {
        OptionRow(
            item: OptionItem(id: "sample-account", title: "Sample account - 1234", subtitle: subtitle),
            mode: .single,
            isSelected: isSelected,
            onTap: {}
        )
    }

    /// Reference rendering from the title-only row before subtitle support.
    func legacyRow(isSelected: Bool) -> some View {
        let colors = EnvironmentValues().designColors
        return Button(action: {}) {
            HStack(spacing: FigmaSize.spacingMedium.scaledToArtwork) {
                Text("Sample account - 1234")
                    .designFont(.body)
                    .foregroundColor(colors.colorsTextPrimaryDark)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                SelectionIndicator(mode: .single, isSelected: isSelected)
            }
            .padding(.vertical, FigmaSize.spacingLarge.scaledToArtwork)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { SeparatorLine() }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    func size(of content: some View) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: width, height: 800))
    }
}
