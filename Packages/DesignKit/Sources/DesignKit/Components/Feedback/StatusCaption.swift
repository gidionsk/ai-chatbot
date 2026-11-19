//
//  StatusCaption.swift
//  DesignKit
//
//  Created by Wendra on 19/11/26.
//

import SwiftUI

/// Status singkat di bawah pesan terakhir, mis. sedang mencari, mengetik, atau menyiapkan jawaban: ikon opsional di
/// kiri lalu teks kecil abu-abu. Ikon dan copy dari pemakai; tanpa ikon tidak ada ruang kosong di kiri teks.
/// TODO: Konfirmasi ukuran ikon, jarak, dan warna teks dengan Figma node 3262-86657.
@MainActor
public struct StatusCaption<Icon: View>: View {
    @Environment(\.designColors) private var colors
    private let text: String
    private let isItalic: Bool
    private let icon: Icon?

    public init(text: String, isItalic: Bool = false, @ViewBuilder icon: () -> Icon) {
        self.text = text
        self.isItalic = isItalic
        self.icon = icon()
    }

    public var body: some View {
        HStack(spacing: FigmaSize.spacingSmall.scaledToArtwork) {
            leadingIcon
            Text(text)
                .designFont(fontRole)
                .foregroundColor(colors.colorsTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var leadingIcon: some View {
        if let icon {
            icon
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)
        }
    }

    private var fontRole: DesignFontRole { isItalic ? .captionItalic : .caption }

    private var iconSize: CGFloat { CustomSizes.StatusCaption.icon.scaledToArtwork }
}

public extension StatusCaption where Icon == EmptyView {
    /// Tanpa ikon: teks langsung di tepi kiri.
    init(text: String, isItalic: Bool = false) {
        self.text = text
        self.isItalic = isItalic
        self.icon = nil
    }
}
