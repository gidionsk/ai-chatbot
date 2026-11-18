//
//  DateChip.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// Label di tengah daftar pesan: tanggal di atas pesan pertama setiap hari, atau status (`style: .filled`).
/// Teks sudah diformat caller. TODO: Konfirmasi warna teks gaya `.card` dengan Figma; sementara dari screenshot.
@MainActor
public struct DateChip: View {
    @Environment(\.designColors) private var colors
    private let text: String
    private let style: DateChipStyle

    public init(text: String, style: DateChipStyle = .card) {
        self.text = text
        self.style = style
    }

    public var body: some View {
        surface
            .frame(maxWidth: .infinity)
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var surface: some View {
        switch style {
        case .card:
            label
                .foregroundColor(colors.colorsTextSecondary)
                .cardStyle(isElevated: false, cornerRadius: cornerRadius)
        case .filled:
            // Figma N600 Black - Medium sama dengan token teks sekunder.
            label
                .foregroundColor(colors.colorsTextPrimaryLight)
                .background(RoundedRectangle(cornerRadius: cornerRadius).fill(colors.colorsTextSecondary))
                .opacity(CustomColors.Chip.filledOpacity)
        }
    }

    private var label: some View {
        Text(text)
            .designFont(.caption)
            .lineLimit(CustomTextLines.dateChip)
            .padding(.horizontal, FigmaSize.spacingMedium.scaledToArtwork)
            .padding(.vertical, FigmaSize.spacingSmall.scaledToArtwork)
    }

    private var cornerRadius: CGFloat { CustomSizes.Chip.cornerRadius.scaledToArtwork }
}
