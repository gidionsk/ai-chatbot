//
//  ActionBanner.swift
//  DesignKit
//
//  Created by Wendra on 19/11/26.
//

import SwiftUI

/// Bar status gelap selebar layar, mis. di bawah header selama mode tertentu: teks di kiri, tombol kecil merah di
/// kanan. Teks panjang turun ke baris berikutnya, tombol tetap seukuran judulnya. Copy dan aksi dari pemakai;
/// nonaktif lewat `.disabled(...)`. TODO: Konfirmasi warna, ukuran teks, dan jarak dengan Figma; sementara dari foto.
@MainActor
public struct ActionBanner: View {
    @Environment(\.designColors) private var colors
    @Environment(\.isEnabled) private var isEnabled
    private let text: String
    private let actionTitle: String
    private let onAction: () -> Void

    public init(text: String, actionTitle: String, onAction: @escaping () -> Void) {
        self.text = text
        self.actionTitle = actionTitle
        self.onAction = onAction
    }

    public var body: some View {
        HStack(spacing: FigmaSize.spacingMedium.scaledToArtwork) {
            Text(text)
                .designFont(.caption)
                .foregroundColor(colors.colorsTextPrimaryLight)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            actionButton
        }
        .padding(.horizontal, FigmaSize.spacingLarge.scaledToArtwork)
        .padding(.vertical, FigmaSize.spacingMedium.scaledToArtwork)
        .background(colors.colorsSurfaceOverlay24)
    }

    private var actionButton: some View {
        Button(action: onAction) {
            Text(actionTitle)
                .designFont(.captionStrong)
                .foregroundColor(colors.colorsTextPrimaryLight)
                .padding(.horizontal, FigmaSize.spacingMedium.scaledToArtwork)
                .padding(.vertical, FigmaSize.spacingSmall.scaledToArtwork)
                .cardStyle(isOutlined: false, isElevated: false, fillColor: buttonColor)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .fixedSize()
    }

    private var buttonColor: Color {
        isEnabled ? colors.colorsButtonActive : colors.colorsIconDisabled
    }
}
