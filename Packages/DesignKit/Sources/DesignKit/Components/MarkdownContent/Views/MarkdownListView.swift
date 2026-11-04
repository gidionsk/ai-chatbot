//
//  MarkdownListView.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// List sedikit masuk dari teks di sekitarnya, dengan hanging indent: penanda di kolom tetap, baris lanjutan
/// rata dengan teks item, bukan penanda.
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
        .padding(.leading, FigmaSize.spacingMedium.scaledToArtwork)
    }
}

// MARK: - Visual sections

private extension MarkdownListView {
    /// Pada list bernomor, penanda terlebar disembunyikan di belakang sebagai penahan lebar kolom, jadi teks
    /// item 9 dan 10 tetap rata. Bullet selalu sama lebar.
    func marker(for item: MarkdownListItem) -> some View {
        ZStack(alignment: .leading) {
            if list.isOrdered {
                markerText(ordinal: list.largestOrdinal).hidden()
            }
            markerText(ordinal: item.ordinal)
        }
        .frame(minWidth: CustomSizes.Markdown.listMarkerWidth.scaledToArtwork, alignment: .leading)
        .accessibilityHidden(!list.isOrdered)
    }

    func markerText(ordinal: Int) -> some View {
        Text(MarkdownSyntax.listMarker(ordinal: ordinal, isOrdered: list.isOrdered, depth: style.listDepth))
            .font(style.fontFace.swiftUIFont(size: style.bodySize))
            .foregroundColor(colors.colorsTextPrimaryDark)
    }
}
