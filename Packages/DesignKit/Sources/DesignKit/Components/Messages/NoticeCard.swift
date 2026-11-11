//
//  NoticeCard.swift
//  DesignKit
//
//  Created by Wendra on 10/11/26.
//

import SwiftUI

/// Kartu pemberitahuan di antara pesan: ikon, judul, lalu isi. Ikon dan copy dari pemakai; baris baru di isi
/// menjadi paragraf. TODO: Konfirmasi ukuran teks dan permukaan kartu dengan Figma.
@MainActor
public struct NoticeCard<Icon: View>: View {
    @Environment(\.designColors) private var colors
    private let title: String
    private let message: String
    private let icon: Icon

    public init(title: String, message: String, @ViewBuilder icon: () -> Icon) {
        self.title = title
        self.message = message
        self.icon = icon()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingMedium.scaledToArtwork) {
            icon
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)
            Text(title)
                .font(
                    FontFace.firaSansSemiBold.swiftUIFont(size: FigmaSize.typographySizeDisplaySmall14.scaledToArtwork)
                )
                .foregroundColor(colors.colorsTextPrimaryDark)
            Text(message)
                .font(FontFace.firaSansRegular.swiftUIFont(size: FigmaSize.typographySizeDisplayTiny12.scaledToArtwork))
                .foregroundColor(colors.colorsTextSecondary)
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(FigmaSize.spacingLarge.scaledToArtwork)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Figma: kartu dengan bayangan, tanpa garis tepi.
        .cardStyle(isOutlined: false)
        .accessibilityElement(children: .combine)
    }

    private var iconSize: CGFloat { FigmaSize.weightIconSmall.scaledToArtwork }
}
