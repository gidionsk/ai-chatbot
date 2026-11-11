//
//  SenderMessageCard.swift
//  DesignKit
//
//  Created by Wendra on 10/11/26.
//

import SwiftUI

/// Pesan masuk dengan identitas pengirim: avatar bulat di kiri, lalu kartu berisi nama pengirim (warna brand) dan
/// teks. Avatar dan copy dari pemakai. TODO: Konfirmasi ukuran avatar dan teks dengan Figma.
@MainActor
public struct SenderMessageCard<Avatar: View>: View {
    @Environment(\.designColors) private var colors
    private let sender: String
    private let text: String
    private let avatar: Avatar

    public init(sender: String, text: String, @ViewBuilder avatar: () -> Avatar) {
        self.sender = sender
        self.text = text
        self.avatar = avatar()
    }

    public var body: some View {
        HStack(alignment: .top, spacing: FigmaSize.spacingMedium.scaledToArtwork) {
            avatar
                .frame(width: avatarSize, height: avatarSize)
                .clipShape(Circle())
                .accessibilityHidden(true)
            content
        }
        .accessibilityElement(children: .combine)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingSmall.scaledToArtwork) {
            Text(sender)
                .font(
                    FontFace.firaSansSemiBold.swiftUIFont(size: FigmaSize.typographySizeDisplayTiny12.scaledToArtwork)
                )
                .foregroundColor(colors.colorsTextBrand)
            Text(text)
                .font(
                    FontFace.firaSansRegular.swiftUIFont(size: FigmaSize.typographySizeDisplaySmall14.scaledToArtwork)
                )
                .foregroundColor(colors.colorsTextPrimaryDark)
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(FigmaSize.spacingMedium.scaledToArtwork)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Figma: kartu dengan bayangan, tanpa garis tepi.
        .cardStyle(isOutlined: false)
    }

    private var avatarSize: CGFloat { FigmaSize.weightIconSmall.scaledToArtwork }
}
