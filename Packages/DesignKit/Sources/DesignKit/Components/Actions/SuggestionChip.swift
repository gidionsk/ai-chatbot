//
//  SuggestionChip.swift
//  DesignKit
//
//  Created by Wendra on 4/11/26.
//

import SwiftUI

/// Chip saran satu ketukan: ikon balas dan teks, selebar isinya. Teks panjang turun ke baris berikutnya supaya
/// saran tidak terpotong. Copy dan aksi dari pemakai.
@MainActor
public struct SuggestionChip: View {
    @Environment(\.designColors) private var colors
    private let text: String
    private let isEnabled: Bool
    private let onTap: () -> Void

    public init(text: String, isEnabled: Bool = true, onTap: @escaping () -> Void) {
        self.text = text
        self.isEnabled = isEnabled
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: FigmaSize.spacingSmall.scaledToArtwork) {
                icon
                label
            }
            .padding(.vertical, FigmaSize.spacingMedium.scaledToArtwork)
            .padding(.leading, FigmaSize.spacingMedium.scaledToArtwork)
            .padding(.trailing, FigmaSize.spacingLarge.scaledToArtwork)
            .cardStyle(
                isElevated: false, cornerRadius: CustomSizes.Chip.suggestionCornerRadius.scaledToArtwork,
                outlineColor: CustomColors.Stroke.strong
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityElement(children: .combine)
    }

    private var icon: some View {
        Image(DesignIcon.reply).resizable().scaledToFit()
            .frame(width: iconSize, height: iconSize)
            .foregroundColor(isEnabled ? colors.colorsIconColored : colors.colorsIconDisabled)
            .accessibilityHidden(true)
    }

    private var label: some View {
        Text(text)
            .font(FontFace.firaSansSemiBold.swiftUIFont(size: FigmaSize.typographySizeDisplayTiny12.scaledToArtwork))
            .foregroundColor(colors.colorsTextPrimaryDark)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var iconSize: CGFloat { FigmaSize.weightIconSmall.scaledToArtwork }
}
