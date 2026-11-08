//
//  MarkdownImageView.swift
//  DesignKit
//
//  Created by Wendra on 4/11/26.
//

import SwiftUI

/// Gambar Markdown dari URL. Tingginya tetap sejak awal agar selesai mengunduh tidak menggeser daftar pesan;
/// teks alt tampil bila unduhan gagal dan menjadi label VoiceOver.
@MainActor
struct MarkdownImageView: View {
    @Environment(\.designColors)
    private var colors
    let url: URL
    let alt: String
    let style: MarkdownTextStyle

    var body: some View {
        RemoteImage(url: url, pointSize: CustomSizes.Markdown.imageMaxSide.scaledToArtwork) {
            colors.colorsSurfaceSelected
        } fallback: {
            Text(alt)
                .font(style.fontFace.swiftUIFont(size: style.bodySize))
                .foregroundColor(colors.colorsTextSecondary)
        }
        .clipShape(RoundedRectangle(cornerRadius: CustomSizes.Markdown.cornerRadius.scaledToArtwork))
        .frame(height: CustomSizes.Markdown.imageHeight.scaledToArtwork, alignment: .top)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Penanda list sejajar baris atas gambar, bukan tepi bawahnya.
        .alignmentGuide(.firstTextBaseline) { $0[.top] + style.bodySize }
        .accessibilityElement()
        .accessibilityLabel(alt)
        .accessibilityAddTraits(.isImage)
    }
}
