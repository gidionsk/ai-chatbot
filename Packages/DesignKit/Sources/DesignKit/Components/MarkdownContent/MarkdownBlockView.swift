//
//  MarkdownBlockView.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// Satu blok Markdown. Teks memakai warna/font token; ukuran garis dan radius di `CustomSizes.Markdown`.
@MainActor
struct MarkdownBlockView: View {
    @Environment(\.designColors)
    private var colors
    let block: MarkdownBlock
    let style: MarkdownTextStyle

    var body: some View {
        switch block {
        case .paragraph(let text):
            textView(text.markdownStyled(size: style.bodySize, style: style, colors: colors))
        case .heading(let level, let text):
            textView(
                text.markdownStyled(size: style.headingSize(level: level), isBold: true, style: style, colors: colors)
            )
            .accessibilityAddTraits(.isHeader)
        case .list(let list):
            MarkdownListView(list: list, style: style)
        case .quote(let blocks):
            quote(blocks)
        case .code(let code):
            MarkdownCodeBlock(code: code, style: style)
        case .divider:
            Rectangle()
                .fill(colors.colorsOutlineNetral)
                .frame(height: FigmaSize.weightOutline.scaledToArtwork)
        case .table(let table):
            MarkdownTableView(table: table, style: style)
        case .image(let url, let alt):
            MarkdownImageView(url: url, alt: alt, style: style)
        }
    }
}

// MARK: - Visual sections

private extension MarkdownBlockView {
    func textView(_ text: AttributedString) -> some View {
        Text(text).fixedSize(horizontal: false, vertical: true)
    }

    /// Garis di kiri setinggi isi quote.
    func quote(_ blocks: [MarkdownBlock]) -> some View {
        HStack(alignment: .top, spacing: FigmaSize.spacingMedium.scaledToArtwork) {
            Rectangle()
                .fill(colors.colorsOutlineNetral)
                .frame(width: CustomSizes.Markdown.quoteBarWidth.scaledToArtwork)
            MarkdownBlocksView(blocks: blocks, style: style)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
