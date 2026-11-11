//
//  FloatingIconButton.swift
//  DesignKit
//
//  Created by Wendra on 11/11/26.
//

import SwiftUI

/// Tombol ikon bulat yang mengambang di atas konten, misalnya untuk kembali ke ujung daftar. Ikon dan aksi dari
/// pemakai; posisi dan label aksesibilitas diatur pemakai. Sisi dan area tap 1:1 Figma `auto_scroll` (36); ikon
/// mengisi sisa sisi setelah padding. Bayangan dari Figma: x 0, y 2, blur 8.
/// TODO: Konfirmasi warna isi dan warna ikon dengan Figma.
@MainActor
public struct FloatingIconButton: View {
    @Environment(\.designColors) private var colors
    private let icon: DesignIcon
    private let onTap: () -> Void

    public init(
        icon: DesignIcon,
        onTap: @escaping () -> Void
    ) {
        self.icon = icon
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .foregroundColor(colors.colorsIconColored)
                .padding(FigmaSize.spacingMedium.scaledToArtwork)
                .frame(
                    width: FigmaSize.weightIconMedium.scaledToArtwork,
                    height: FigmaSize.weightIconMedium.scaledToArtwork
                )
                .background(surface)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var surface: some View {
        Circle().fill(colors.colorsSurfacePrimary)
            .shadow(
                color: CustomColors.Shadow.strong,
                radius: FigmaSize.spacingMedium.scaledToArtwork,
                y: CustomSizes.Shadow.offsetY.scaledToArtwork
            )
    }
}
