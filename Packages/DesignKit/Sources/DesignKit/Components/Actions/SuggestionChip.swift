//
//  SuggestionChip.swift
//  DesignKit
//
//  Created by Wendra on 4/11/26.
//

import SwiftUI

/// Chip saran satu ketukan: ikon balas dan teks, selebar isinya. Teks panjang turun ke baris berikutnya supaya
/// saran tidak terpotong. Copy dan aksi dari pemakai. Nonaktif lewat `.disabled(...)` dari pemakai.
@MainActor
public struct SuggestionChip: View {
    @Environment(\.designColors) private var colors
    @Environment(\.isEnabled) private var isEnabled
    private let text: String
    private let onTap: () -> Void

    public init(text: String, onTap: @escaping () -> Void) {
        self.text = text
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
            .designFont(.captionStrong)
            .foregroundColor(colors.colorsTextPrimaryDark)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var iconSize: CGFloat { FigmaSize.weightIconSmall.scaledToArtwork }
}
