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
                Text(item.title)
                    .designFont(.body)
                    .foregroundColor(colors.colorsTextPrimaryDark)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                SelectionIndicator(mode: mode, isSelected: isSelected)
            }
            .padding(.vertical, FigmaSize.spacingLarge.scaledToArtwork)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { SeparatorLine() }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
