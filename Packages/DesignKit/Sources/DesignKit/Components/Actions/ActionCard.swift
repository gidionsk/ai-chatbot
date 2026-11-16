//
//  ActionCard.swift
//  DesignKit
//
//  Created by Wendra on 27/10/26.
//

import SwiftUI

/// Kartu aksi satu ketukan: ikon di kotak, judul, deskripsi, dan chevron bulat.
/// TODO: Cocokkan peran teks judul dan deskripsi dengan Figma; sementara estimasi dari screenshot.
/// Ikon disuplai caller (gambar lokal atau `RemoteImage`); copy juga dari caller. Nonaktif lewat `.disabled(...)`
/// dari pemakai.
@MainActor
public struct ActionCard<Icon: View>: View {
    @Environment(\.designColors) private var colors
    @Environment(\.isEnabled) private var isEnabled
    private let title: String
    private let description: String
    private let onTap: () -> Void
    private let icon: Icon

    public init(
        title: String,
        description: String,
        onTap: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) {
        self.title = title
        self.description = description
        self.onTap = onTap
        self.icon = icon()
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: FigmaSize.spacingMedium.scaledToArtwork) {
                iconBox
                texts
                chevron
            }
            .padding(FigmaSize.spacingLarge.scaledToArtwork)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Figma `default_recommendation`: tanpa garis tepi, hanya bayangan.
            .cardStyle(isOutlined: false)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var iconBox: some View {
        icon
            .frame(width: iconSize, height: iconSize)
            .frame(width: boxSize, height: boxSize)
            .cardStyle(isOutlined: false, isElevated: false, fillColor: colors.colorsSurfaceWarning)
            .accessibilityHidden(true)
    }

    private var texts: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingSmall.scaledToArtwork) {
            Text(title)
                .designFont(.bodyStrong)
                .foregroundColor(colors.colorsTextPrimaryDark)
            Text(description)
                .designFont(.caption)
                .foregroundColor(colors.colorsTextSecondary)
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Abu-abu saat nonaktif agar terlihat tidak bisa diketuk.
    private var chevron: some View {
        Image(DesignIcon.chevronRight).resizable().scaledToFit()
            .foregroundColor(colors.colorsIconLight)
            .frame(width: chevronSize, height: chevronSize)
            .background(Circle().fill(isEnabled ? colors.colorsButtonActive : colors.colorsIconDisabled))
            .accessibilityHidden(true)
    }
}

// MARK: - Helpers

private extension ActionCard {
    var iconSize: CGFloat { FigmaSize.weightIconSmall.scaledToArtwork }
    var boxSize: CGFloat { CustomSizes.ActionCard.iconBox.scaledToArtwork }
    var chevronSize: CGFloat { CustomSizes.ActionCard.chevron.scaledToArtwork }
}
