//
//  ConfirmationPrompt.swift
//  DesignKit
//
//  Created by Wendra on 20/11/26.
//

import SwiftUI

/// Isi bottom sheet konfirmasi: judul, keterangan, lalu aksi utama dan tombol batal bertumpuk selebar sheet (footer
/// yang menempel). Copy dan aksi dari pemakai; menutup sheet tetap tugas pemakai. Padding isi milik komponen ini.
/// TODO: Konfirmasi ukuran teks, jarak, dan warna tombol dengan Figma node 1903-8266; sementara dari foto, dan aksi
/// utama memakai `FilledButton` `.regular` yang ada (di foto Figma merah).
@MainActor
public struct ConfirmationPrompt: View {
    @Environment(\.designColors) private var colors
    private let title: String
    private let message: String
    private let confirmTitle: String
    private let cancelTitle: String
    private let onConfirm: () -> Void
    private let onCancel: () -> Void

    public init(
        title: String,
        message: String,
        confirmTitle: String,
        cancelTitle: String,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.confirmTitle = confirmTitle
        self.cancelTitle = cancelTitle
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingSmall.scaledToArtwork) {
            Text(title)
                .designFont(.title)
                .foregroundColor(colors.colorsTextPrimaryDark)
            Text(message)
                .designFont(.body)
                .foregroundColor(colors.colorsTextSecondary)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.horizontal, .top], FigmaSize.spacingLarge.scaledToArtwork)
        .bottomSheetFooter { actions }
    }

    /// Padding di semua sisi milik tombol, supaya jarak ke isi dan ke tepi bawah ikut footer yang menempel.
    private var actions: some View {
        VStack(spacing: FigmaSize.spacingMedium.scaledToArtwork) {
            FilledButton(title: confirmTitle, onTap: onConfirm)
                .accessibilityIdentifier(ComponentIdentifier.ConfirmationPrompt.confirm)
            FilledButton(title: cancelTitle, variant: .outlined, onTap: onCancel)
                .accessibilityIdentifier(ComponentIdentifier.ConfirmationPrompt.cancel)
        }
        .padding(FigmaSize.spacingLarge.scaledToArtwork)
    }
}
