//
//  FloatingIconButton.swift
//  DesignKit
//
//  Created by Wendra on 11/11/26.
//

import SwiftUI

/// Tombol ikon bulat yang mengambang di atas konten, misalnya untuk kembali ke ujung daftar. Ikon, label
/// aksesibilitas dan aksi dari pemakai; posisi diatur pemakai. Sisi dan area tap 1:1 Figma `auto_scroll` (36),
/// bayangan dari Figma. TODO: Konfirmasi warna isi, warna ikon dan ukuran ikon dengan Figma.
@MainActor
public struct FloatingIconButton: View {
    @Environment(\.designColors) private var colors
    private let icon: DesignIcon
    private let label: String
    private let onTap: () -> Void

    public init(icon: DesignIcon, label: String, onTap: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            Image(icon).resizable().scaledToFit()
                .frame(width: iconSide, height: iconSide)
                .foregroundColor(colors.colorsIconColored)
                .frame(width: side, height: side)
                .background(surface)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var surface: some View {
        Circle().fill(colors.colorsSurfacePrimary)
            .shadow(
                color: CustomColors.Shadow.strong,
                radius: CustomSizes.FloatingIconButton.shadowRadius.scaledToArtwork,
                y: CustomSizes.Shadow.offsetY.scaledToArtwork
            )
    }

    private var side: CGFloat { FigmaSize.weightIconMedium.scaledToArtwork }

    private var iconSide: CGFloat { FigmaSize.weightIconSmall.scaledToArtwork }
}
