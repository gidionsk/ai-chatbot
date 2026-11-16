//
//  DateChip.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// Label tanggal di tengah daftar pesan, di atas pesan pertama setiap hari. Teks sudah diformat caller.
/// Permukaan kartu tanpa bayangan. TODO: Konfirmasi warna teks dengan Figma; sementara dari screenshot.
@MainActor
public struct DateChip: View {
    @Environment(\.designColors) private var colors
    private let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .designFont(.caption)
            .foregroundColor(colors.colorsTextSecondary)
            .lineLimit(CustomTextLines.dateChip)
            .padding(.horizontal, FigmaSize.spacingMedium.scaledToArtwork)
            .padding(.vertical, FigmaSize.spacingSmall.scaledToArtwork)
            .cardStyle(isElevated: false, cornerRadius: CustomSizes.Chip.cornerRadius.scaledToArtwork)
            .frame(maxWidth: .infinity)
            .accessibilityAddTraits(.isHeader)
    }
}
