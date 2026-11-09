//
//  TextChip.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// Chip teks tanpa aksi, satu baris, di atas permukaan kartu tanpa bayangan. Teks sudah diformat pemakai; posisi dan
/// peran aksesibilitas (mis. judul kelompok) juga milik pemakai. TODO: Konfirmasi warna teks dengan Figma.
@MainActor
public struct TextChip: View {
    @Environment(\.designColors) private var colors
    private let text: String
    private let fontFace: FontFace

    public init(text: String, fontFace: FontFace = .firaSansRegular) {
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
