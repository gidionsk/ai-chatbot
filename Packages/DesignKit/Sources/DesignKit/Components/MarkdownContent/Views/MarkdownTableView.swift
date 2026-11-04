//
//  MarkdownTableView.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// Tabel dengan lebar kolom sama, header berlatar dan tebal, garis antarbaris, dan perataan per kolom.
/// TODO: Tabel lebih dari tiga kolom belum punya pola Figma; sementara tetap dibagi rata.
@MainActor
struct MarkdownTableView: View {
    @Environment(\.designColors)
    private var colors
    let table: MarkdownTable
    let style: MarkdownTextStyle

    var body: some View {
        VStack(spacing: .zero) {
            if !table.header.isEmpty {
                row(table.header, isHeader: true)
                    .background(colors.colorsSurfaceTableHeader)
            }
            ForEach(Array(table.rows.enumerated()), id: \.offset) { index, cells in
                if index > .zero || !table.header.isEmpty {
                    separator
                }
                row(cells, isHeader: false)
            }
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(colors.colorsOutlineNetral, lineWidth: FigmaSize.weightOutline.scaledToArtwork))
    }
}

// MARK: - Visual sections

private extension MarkdownTableView {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: CustomSizes.Markdown.cornerRadius.scaledToArtwork)
    }

    var separator: some View {
        Rectangle()
            .fill(colors.colorsOutlineNetral)
            .frame(height: FigmaSize.weightOutline.scaledToArtwork)
    }

    func row(_ cells: [AttributedString], isHeader: Bool) -> some View {
        HStack(alignment: .top, spacing: .zero) {
            ForEach(Array(cells.enumerated()), id: \.offset) { column, cell in
                let alignment = table.alignments[column]
                Text(cell.markdownStyled(size: style.bodySize, isBold: isHeader, style: style, colors: colors))
                    .multilineTextAlignment(alignment.textAlignment)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: alignment.frameAlignment)
                    .padding(FigmaSize.spacingMedium.scaledToArtwork)
            }
        }
    }
}
