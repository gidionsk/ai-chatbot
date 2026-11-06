//
//  LinkedText.swift
//  DesignKit
//
//  Created by Wendra on 6/11/26.
//

import SwiftUI

/// Kalimat kecil rata tengah dengan bagian yang bisa diketuk, ditulis sebagai link Markdown:
/// `Baca [ketentuan](terms).` Tujuan link diabaikan: tap diteruskan ke `onOpen`, tanpa Safari fallback.
@MainActor
public struct LinkedText: View {
    @Environment(\.designColors) private var colors
    private let markdown: String
    private let onOpen: () -> Void

    public init(markdown: String, onOpen: @escaping () -> Void) {
        self.markdown = markdown
        self.onOpen = onOpen
    }

    public var body: some View {
        Text(AttributedString.linked(markdown: markdown, linkColor: colors.colorsTextBrand))
            .font(FontFace.firaSansRegular.swiftUIFont(size: FigmaSize.typographySizeDisplayTiny12.scaledToArtwork))
            .foregroundColor(colors.colorsTextSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .tint(colors.colorsTextBrand)
            .environment(\.openURL, OpenURLAction(handler: open))
    }
}

// MARK: - Helpers

private extension LinkedText {
    func open(_ url: URL) -> OpenURLAction.Result {
        onOpen()
        return .handled
    }
}
