//
//  NoticeCard.swift
//  DesignKit
//
//  Created by Wendra on 10/11/26.
//

import SwiftUI

/// Kartu pemberitahuan di antara pesan: ikon, judul, lalu isi. Ikon dan copy dari pemakai; baris baru di isi
/// menjadi paragraf. Aksi opsional (mis. tombol batal) di bawah garis pemisah di dalam kartu; tanpa aksi tidak ada
/// garis maupun ruang kosong. Teks dibaca VoiceOver sebagai satu elemen, aksinya tetap elemen sendiri.
/// TODO: Konfirmasi ukuran teks, permukaan kartu, dan jarak garis pemisah dengan Figma.
@MainActor
public struct NoticeCard<Icon: View, Action: View>: View {
    @Environment(\.designColors) private var colors
    private let title: String
    private let message: String
    private let icon: Icon
    private let action: Action?

    public init(
        title: String,
        message: String,
        @ViewBuilder icon: () -> Icon,
        @ViewBuilder action: () -> Action
    ) {
        self.title = title
        self.message = message
        self.icon = icon()
        self.action = action()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            content
            actionSection
        }
        .padding(FigmaSize.spacingLarge.scaledToArtwork)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Figma: kartu dengan bayangan, tanpa garis tepi.
        .cardStyle(isOutlined: false)
        .accessibilityElement(children: .contain)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingMedium.scaledToArtwork) {
            icon
                .frame(width: iconSize, height: iconSize)
                .accessibilityHidden(true)
            Text(title)
                .designFont(.bodyStrong)
                .foregroundColor(colors.colorsTextPrimaryDark)
            Text(message)
                .designFont(.caption)
                .foregroundColor(colors.colorsTextSecondary)
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var actionSection: some View {
        if let action {
            SeparatorLine()
            action
        }
    }

    private var iconSize: CGFloat { FigmaSize.weightIconSmall.scaledToArtwork }
}

public extension NoticeCard where Action == EmptyView {
    /// Tanpa aksi: kartu berakhir di teks isi.
    init(title: String, message: String, @ViewBuilder icon: () -> Icon) {
        self.title = title
        self.message = message
        self.icon = icon()
        self.action = nil
    }
}
