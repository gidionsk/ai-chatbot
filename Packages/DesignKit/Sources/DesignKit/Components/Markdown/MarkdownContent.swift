//
//  MarkdownContent.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// Teks Markdown (jawaban bot): heading, paragraf, list bertingkat dengan hanging indent, task list, quote, divider,
/// code block, tabel, gambar, serta tebal/miring/coret/kode/link. Tanpa background; margin milik daftar pemakai.
/// Link tidak pernah dibuka sendiri (tanpa Safari fallback): tujuan link diteruskan ke `onOpenLink` apa adanya, jadi
/// bisa berupa alamat web, deeplink, atau nama tujuan seperti `terms`.
@MainActor
public struct MarkdownContent: View {
    @Environment(\.designColors) private var colors
    private let document: MarkdownDocument
    private let style: MarkdownTextStyle
    private let onOpenLink: (String) -> Void

    public init(
        document: MarkdownDocument, fontFace: FontFace = .firaSansRegular, boldFontFace: FontFace = .firaSansBold,
        italicFontFace: FontFace = .firaSansItalic, boldItalicFontFace: FontFace = .firaSansBoldItalic,
        role: MarkdownTextRole = .body, onOpenLink: @escaping (String) -> Void
    ) {
        self.document = document
        self.style = MarkdownTextStyle(
            fontFace: fontFace, boldFontFace: boldFontFace, italicFontFace: italicFontFace,
            boldItalicFontFace: boldItalicFontFace, role: role
        )
        self.onOpenLink = onOpenLink
    }

    public var body: some View {
        MarkdownBlocksView(blocks: document.blocks, style: style)
            .multilineTextAlignment(style.textAlignment)
            .frame(maxWidth: .infinity, alignment: style.alignment)
            .tint(style.linkColor(in: colors))
            .environment(\.openURL, OpenURLAction(handler: openLink))
    }
}

// MARK: - Helpers

private extension MarkdownContent {
    func openLink(_ url: URL) -> OpenURLAction.Result {
        onOpenLink(url.absoluteString)
        return .handled
    }
}
