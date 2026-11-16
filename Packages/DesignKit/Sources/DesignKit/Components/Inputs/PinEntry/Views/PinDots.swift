//
//  PinDots.swift
//  DesignKit
//
//  Created by Wendra on 16/11/26.
//

import SwiftUI

/// Deretan titik PIN: satu titik per digit, berwarna untuk digit yang sudah diisi. Angkanya sendiri tidak pernah
/// ditampilkan. Bagi VoiceOver satu elemen berlabel judul dengan nilai jumlah digit yang sudah diisi, tanpa angka PIN.
@MainActor
struct PinDots: View {
    @Environment(\.designColors) private var colors
    let label: String
    let filledCount: Int
    let length: Int

    var body: some View {
        HStack(spacing: CustomSizes.PinEntry.dotSpacing.scaledToArtwork) {
            ForEach(Int.zero..<length, id: \.self) { index in
                Circle()
                    .fill(index < filledCount ? colors.colorsIconColored : colors.colorsSelectionEmptyDefault)
                    .padding(CustomSizes.PinEntry.dotInset.scaledToArtwork)
                    .frame(width: dotSize, height: dotSize)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityValue(String(filledCount))
        .accessibilityIdentifier(ComponentIdentifier.PinEntry.dots)
    }

    private var dotSize: CGFloat { CustomSizes.PinEntry.dotSize.scaledToArtwork }
}
