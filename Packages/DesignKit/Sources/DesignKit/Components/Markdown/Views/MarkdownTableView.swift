//
//  MarkdownTableView.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// Tabel tanpa bingkai, rata dengan teks di sekitarnya: lebar kolom sama, header tebal, garis di bawah setiap
/// baris, dan perataan per kolom. Baris ringkasan memberi label seluruh lebar di samping nilai terakhir.
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
                separator
            }
            ForEach(Array(table.rows.enumerated()), id: \.offset) { _, cells in
                if table.isSummaryRow(cells) {
                    summaryRow(cells)
                } else {
                    row(cells, isHeader: false)
                }
                separator
            }
        }
    }
}

// MARK: - Visual sections

private extension MarkdownTableView {
    var separator: some View {
        Rectangle()
            .fill(colors.colorsOutlineNetral)
            .frame(height: FigmaSize.weightOutline.scaledToArtwork)
    }

    func row(_ cells: [AttributedString], isHeader: Bool) -> some View {
        HStack(alignment: .top, spacing: FigmaSize.spacingMedium.scaledToArtwork) {
            ForEach(Array(cells.enumerated()), id: \.offset) { column, cell in
                let alignment = table.alignments[column]
                text(cell, isHeader: isHeader)
                    .multilineTextAlignment(alignment.textAlignment)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: alignment.frameAlignment)
            }
        }
        .padding(.vertical, FigmaSize.spacingMedium.scaledToArtwork)
    }

    func summaryRow(_ cells: [AttributedString]) -> some View {
        HStack(alignment: .top, spacing: FigmaSize.spacingMedium.scaledToArtwork) {
            if let label = cells.first, let value = cells.last {
                text(label, isHeader: false)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                text(value, isHeader: false)
                    .fixedSize()
            }
        }
        .padding(.vertical, FigmaSize.spacingMedium.scaledToArtwork)
    }

    func text(_ cell: AttributedString, isHeader: Bool) -> Text {
        Text(cell.markdownStyled(size: style.bodySize, isBold: isHeader, style: style, colors: colors))
    }
}
