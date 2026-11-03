//
//  DateChip.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// Label tanggal di tengah daftar pesan, di atas pesan pertama setiap hari. Teks sudah diformat caller.
/// TODO: Cocokkan padding dan warna surface dengan Figma; sementara estimasi dari screenshot.
@MainActor
public struct DateChip: View {
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
            .font(fontFace.swiftUIFont(size: FigmaSize.typographySizeDisplaySmall14.scaledToArtwork))
            .foregroundColor(colors.colorsTextPrimaryDark)
            .lineLimit(CustomTextLines.dateChip)
            .padding(.horizontal, FigmaSize.spacingLarge.scaledToArtwork)
            .padding(.vertical, FigmaSize.spacingSmall.scaledToArtwork)
            .background(Capsule().fill(colors.colorsSurfaceSelected))
            .frame(maxWidth: .infinity)
            .accessibilityAddTraits(.isHeader)
    }
}
