//
//  TextChip.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// Label teks pendek di atas permukaan kartu tanpa bayangan, selebar isinya. Teks sudah diformat caller; posisi
/// dan peran aksesibilitas milik pemakai. TODO: Konfirmasi warna teks dengan Figma; sementara dari screenshot.
@MainActor
public struct TextChip: View {
    @Environment(\.designColors)
    private var colors
    private let text: String
    private let fontFace: FontFace

    public init(text: String, fontFace: FontFace = .openSansRegular) {
        self.text = text
        self.fontFace = fontFace
    }

    public var body: some View {
        Text(text)
            .font(fontFace.swiftUIFont(size: FigmaSize.typographySizeDisplayTiny12.scaledToArtwork))
            .foregroundColor(colors.colorsTextSecondary)
            .lineLimit(CustomTextLines.textChip)
            .padding(.horizontal, FigmaSize.spacingMedium.scaledToArtwork)
            .padding(.vertical, FigmaSize.spacingSmall.scaledToArtwork)
            .cardStyle(isElevated: false, cornerRadius: CustomSizes.Chip.cornerRadius.scaledToArtwork)
    }
}
