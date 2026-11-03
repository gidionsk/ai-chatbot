//
//  MarkdownBlocksView.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// Blok berurutan dengan jarak antarblok yang sama; dipakai di akar, di dalam quote, dan di dalam item list.
@MainActor
struct MarkdownBlocksView: View {
    let blocks: [MarkdownBlock]
    let style: MarkdownTextStyle

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingMedium.scaledToArtwork) {
            // Isi statis per pesan: posisi blok cukup sebagai id.
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                MarkdownBlockView(block: block, style: style)
            }
        }
    }
}
