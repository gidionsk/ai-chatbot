//
//  FilledLinkButton.swift
//  DesignKit
//
//  Created by Wendra on 10/11/26.
//

import SwiftUI

/// Tombol selebar wadah dengan latar gelap dan label bergaris bawah, untuk aksi pembatalan di bawah kartu.
/// Copy dan aksi dari pemakai.
@MainActor
public struct FilledLinkButton: View {
    @Environment(\.designColors) private var colors
    private let title: String
    private let isEnabled: Bool
    private let onTap: () -> Void

    public init(title: String, isEnabled: Bool = true, onTap: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(
                    FontFace.firaSansSemiBold.swiftUIFont(size: FigmaSize.typographySizeDisplayTiny12.scaledToArtwork)
                )
                .underline()
                .foregroundColor(colors.colorsTextPrimaryLight)
                .padding(FigmaSize.spacingMedium.scaledToArtwork)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: CustomSizes.Card.cornerRadius.scaledToArtwork)
                        .fill(isEnabled ? CustomColors.Button.muted : colors.colorsIconDisabled)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
