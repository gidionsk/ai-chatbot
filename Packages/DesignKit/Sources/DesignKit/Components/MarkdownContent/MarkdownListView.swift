//
//  MarkdownListView.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// List dengan hanging indent: penanda di kolom tetap, baris lanjutan rata dengan teks item, bukan penanda.
@MainActor
struct MarkdownListView: View {
    @Environment(\.designColors)
    private var colors
    let list: MarkdownList
    let style: MarkdownTextStyle

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingSmall.scaledToArtwork) {
            ForEach(Array(list.items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .firstTextBaseline, spacing: FigmaSize.spacingSmall.scaledToArtwork) {
                    marker(for: item)
                    MarkdownBlocksView(blocks: item.blocks, style: style.nested())
                }
            }
        }
    }
}

// MARK: - Visual sections

private extension MarkdownListView {
    func marker(for item: MarkdownListItem) -> some View {
        Text(MarkdownSyntax.listMarker(ordinal: item.ordinal, isOrdered: list.isOrdered, depth: style.listDepth))
            .font(style.fontFace.swiftUIFont(size: style.bodySize))
            .foregroundColor(colors.colorsTextPrimaryDark)
            .frame(minWidth: CustomSizes.Markdown.listMarkerWidth.scaledToArtwork, alignment: .leading)
            .accessibilityHidden(!list.isOrdered)
    }
}
