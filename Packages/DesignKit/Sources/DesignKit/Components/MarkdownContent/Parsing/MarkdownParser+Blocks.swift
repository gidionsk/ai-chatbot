//
//  MarkdownParser+Blocks.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import Foundation

extension MarkdownParser {
    /// Simpul anak (item list, baris dan sel tabel) dibaca oleh induknya, jadi di level ini menjadi nil.
    static func block(from node: MarkdownNode) -> MarkdownBlock? {
        switch node.kind {
        case .paragraph:
            return .paragraph(node.text)
        case .header(let level):
            return .heading(level: level, text: node.text)
        case .codeBlock:
            return .code(String(node.text.characters).trimmingCharacters(in: .newlines))
        case .thematicBreak:
            return .divider
        case .blockQuote:
            return .quote(node.children.compactMap(block(from:)))
        case .orderedList, .unorderedList:
            return .list(list(from: node))
        case .table(let columns):
            return .table(table(columns: columns, rows: node.children))
        default:
            return nil
        }
    }
}

// MARK: - Container

private extension MarkdownParser {
    static func list(from node: MarkdownNode) -> MarkdownList {
        let items = node.children.map { item -> MarkdownListItem in
            var ordinal = MarkdownSyntax.firstOrdinal
            if case .listItem(let value) = item.kind {
                ordinal = value
            }
            return MarkdownListItem(ordinal: ordinal, blocks: item.children.compactMap(block(from:)))
        }
        return MarkdownList(isOrdered: node.kind == .orderedList, items: items)
    }

    static func table(columns: [PresentationIntent.TableColumn], rows: [MarkdownNode]) -> MarkdownTable {
        let cells = rows.map { row in
            var cells = Array(repeating: AttributedString(), count: columns.count)
            for cell in row.children {
                if case .tableCell(let column) = cell.kind, cells.indices.contains(column) {
                    cells[column] = cell.text
                }
            }
            return cells
        }
        let isHeaderFirst = rows.first?.kind == .tableHeaderRow
        return MarkdownTable(
            alignments: columns.map { MarkdownColumnAlignment($0.alignment) },
            header: isHeaderFirst ? cells.first ?? [] : [],
            rows: isHeaderFirst ? Array(cells.dropFirst()) : cells
        )
    }
}
