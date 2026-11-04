//
//  MessageBubble.swift
//  DesignKit
//
//  Created by Wendra on 28/10/26.
//

import SwiftUI

/// Satu pesan teks. Keluar (pengguna): bubble merah rata kanan dengan sudut kanan bawah siku, teks putih.
/// Masuk: tanpa background, selebar konten, rata kiri. Margin antar pesan milik daftar pemakai.
/// `failureNote` (hanya pesan keluar): bubble abu-abu dengan catatan merah miring di bawahnya.
@MainActor
public struct MessageBubble: View {
    @Environment(\.designColors)
    private var colors
    private let text: String
    private let isOutgoing: Bool
    private let failureNote: String?
    private let fontFace: FontFace

    public init(text: String, isOutgoing: Bool, failureNote: String? = nil, fontFace: FontFace = .firaSansRegular) {
        self.text = text
        self.isOutgoing = isOutgoing
        self.failureNote = isOutgoing ? failureNote : nil
        self.fontFace = fontFace
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: FigmaSize.spacingSmall.scaledToArtwork) {
            message
            note
        }
        .padding(.leading, isOutgoing ? CustomSizes.MessageBubble.outgoingLeadingInset.scaledToArtwork : .zero)
        .frame(maxWidth: .infinity, alignment: isOutgoing ? .trailing : .leading)
        // VoiceOver membaca pesan dan catatan gagal sebagai satu elemen.
        .accessibilityElement(children: .combine)
    }

    private var message: some View {
        Text(text)
            .font(fontFace.swiftUIFont(size: FigmaSize.typographySizeDisplaySmall14.scaledToArtwork))
            .foregroundColor(isOutgoing ? colors.colorsTextPrimaryLight : colors.colorsTextPrimaryDark)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, isOutgoing ? FigmaSize.spacingLarge.scaledToArtwork : .zero)
            .padding(.vertical, isOutgoing ? FigmaSize.spacingMedium.scaledToArtwork : .zero)
            .background(surface)
    }

    @ViewBuilder
    private var note: some View {
        if let failureNote {
            Text(failureNote)
                .font(FontFace.firaSansItalic.swiftUIFont(size: FigmaSize.typographySizeDisplayTiny12.scaledToArtwork))
                .foregroundColor(colors.colorsTextNegative)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Figma memakai #BEC3D0 untuk bubble gagal; token terdekat (#B2B7C6) dipakai sampai token surface-nya ada.
    @ViewBuilder
    private var surface: some View {
        if isOutgoing {
            MessageBubbleShape(cornerRadius: CustomSizes.MessageBubble.cornerRadius.scaledToArtwork)
                .fill(failureNote == nil ? colors.colorsButtonActive : colors.colorsIconDisabled)
        }
    }
}
