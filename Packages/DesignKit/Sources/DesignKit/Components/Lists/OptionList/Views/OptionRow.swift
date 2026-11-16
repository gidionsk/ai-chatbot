//
//  OptionRow.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI

/// Satu baris di `OptionList`: teks pilihan, penanda di kanan, dan garis pemisah di bawahnya.
@MainActor
struct OptionRow: View {
    @Environment(\.designColors) private var colors
    let item: OptionItem
    let mode: OptionSelectionMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FigmaSize.spacingMedium.scaledToArtwork) {
                label
                SelectionIndicator(mode: mode, isSelected: isSelected)
            }
            .padding(.vertical, FigmaSize.spacingLarge.scaledToArtwork)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { SeparatorLine() }
        .accessibilityLabel(item.title)
        .accessibilityValue(item.subtitle ?? String())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingSmall.scaledToArtwork) {
            Text(item.title)
                .designFont(.body)
                .foregroundColor(colors.colorsTextPrimaryDark)
            if let subtitle = item.subtitle {
                Text(subtitle)
                    .designFont(.caption)
                    .foregroundColor(colors.colorsTextSecondary)
            }
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
