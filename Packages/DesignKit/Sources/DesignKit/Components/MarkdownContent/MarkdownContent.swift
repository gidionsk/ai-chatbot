//
//  MarkdownContent.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// Teks Markdown (jawaban bot): heading, paragraf, list bertingkat dengan hanging indent, quote, divider,
/// code block, tabel, serta tebal/miring/coret/kode/link. Tanpa background; margin milik daftar pemakai.
/// Link tidak pernah dibuka sendiri (tanpa Safari fallback): tap diteruskan ke `onOpenLink`.
@MainActor
public struct MarkdownContent: View {
    private let document: MarkdownDocument
    private let style: MarkdownTextStyle
    private let onOpenLink: (URL) -> Void

    public init(
        document: MarkdownDocument, fontFace: FontFace = .firaSansRegular, boldFontFace: FontFace = .firaSansBold,
        italicFontFace: FontFace = .firaSansItalic, onOpenLink: @escaping (URL) -> Void
    ) {
        self.document = document
        self.style = MarkdownTextStyle(fontFace: fontFace, boldFontFace: boldFontFace, italicFontFace: italicFontFace)
        self.onOpenLink = onOpenLink
    }

    public var body: some View {
        MarkdownBlocksView(blocks: document.blocks, style: style)
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.openURL, OpenURLAction(handler: openLink))
    }
}

// MARK: - Helpers

private extension MarkdownContent {
    func openLink(_ url: URL) -> OpenURLAction.Result {
        onOpenLink(url)
        return .handled
    }
}
