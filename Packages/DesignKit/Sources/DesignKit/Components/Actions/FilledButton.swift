//
//  FilledButton.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI

/// Tombol selebar wadah. `.regular` = latar gelap untuk aksi utama (Konfirmasi, Pilih); `.outlined` = ukuran sama,
/// hanya garis tepi, untuk aksi kedua di sampingnya (Batalkan); `.link` = teks kecil bergaris bawah, mis. "Batalkan
/// proses ini" di bawah kartu status. Copy dan aksi dari pemakai. Nonaktif lewat `.disabled(...)` dari pemakai.
/// TODO: Konfirmasi warna, ukuran teks, tinggi, dan garis `.outlined` dengan Figma; sementara dari foto.
@MainActor
public struct FilledButton: View {
    @Environment(\.designColors) private var colors
    @Environment(\.isEnabled) private var isEnabled
    private let title: String
    private let variant: FilledButtonVariant
    private let onTap: () -> Void

    public init(
        title: String,
        variant: FilledButtonVariant = .regular,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.variant = variant
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            Text(title)
                // `underline` milik `Text` (iOS 15); setelah `.designFont` yang tersisa versi View milik iOS 16.
                .underline(variant == .link)
                .designFont(fontRole)
                .foregroundColor(variant == .outlined ? accentColor : colors.colorsTextPrimaryLight)
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, verticalPadding)
                .frame(maxWidth: .infinity)
                .cardStyle(
                    isOutlined: variant == .outlined,
                    isElevated: false,
                    outlineColor: accentColor,
                    fillColor: variant == .outlined ? nil : accentColor
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers

private extension FilledButton {
    /// Latar `.regular`/`.link`, atau garis dan teks `.outlined`; abu-abu saat nonaktif.
    var accentColor: Color {
        isEnabled ? CustomColors.Button.muted : disabledColor
    }

    var fontRole: DesignFontRole {
        switch variant {
        case .regular, .outlined:
            return .bodyStrong
        case .link:
            return .captionStrong
        }
    }

    var verticalPadding: CGFloat {
        switch variant {
        case .regular, .outlined:
            return CustomSizes.FilledButton.verticalPadding.scaledToArtwork
        case .link:
            return FigmaSize.spacingMedium.scaledToArtwork
        }
    }

    var horizontalPadding: CGFloat {
        switch variant {
        case .regular, .outlined:
            return .zero
        case .link:
            return FigmaSize.spacingMedium.scaledToArtwork
        }
    }

    /// Warna nonaktif masing-masing tetap seperti sebelum kedua tombol digabung.
    var disabledColor: Color {
        switch variant {
        case .regular:
            return colors.colorsButtonDisable
        case .outlined:
            return colors.colorsTextDisabled
        case .link:
            return colors.colorsIconDisabled
        }
    }
}
