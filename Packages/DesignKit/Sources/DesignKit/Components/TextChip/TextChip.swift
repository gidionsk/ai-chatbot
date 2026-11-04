//
//  TextChip.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// Label teks pendek di dalam kapsul, selebar isinya. Teks sudah diformat caller; posisi dan peran aksesibilitas
/// milik pemakai.
/// TODO: Cocokkan padding dan warna surface dengan Figma; sementara estimasi dari screenshot.
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
            .font(fontFace.swiftUIFont(size: FigmaSize.typographySizeDisplaySmall14.scaledToArtwork))
            .foregroundColor(colors.colorsTextPrimaryDark)
            .lineLimit(CustomTextLines.textChip)
            .padding(.horizontal, FigmaSize.spacingLarge.scaledToArtwork)
            .padding(.vertical, FigmaSize.spacingSmall.scaledToArtwork)
            .background(Capsule().fill(colors.colorsSurfaceSelected))
    }
}
