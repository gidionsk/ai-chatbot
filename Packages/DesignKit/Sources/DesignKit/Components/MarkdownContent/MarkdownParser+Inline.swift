//
//  MarkdownParser+Inline.swift
//  DesignKit
//
//  Created by Wendra on 4/11/26.
//

import Foundation

extension MarkdownParser {
    /// Gambar tidak bisa berada di dalam `Text`, jadi paragraf dipecah berurutan: teks, gambar, teks. Gambar di
    /// heading dan sel tabel tetap tampil sebagai teks alt.
    static func paragraphBlocks(from text: AttributedString) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var pending = AttributedString()
        for run in text.runs {
            if let url = run.imageURL {
                appendParagraph(pending, to: &blocks)
                pending = AttributedString()
                blocks.append(.image(url: url, alt: String(text[run.range].characters)))
            } else {
                pending.append(text[run.range])
            }
        }
        appendParagraph(pending, to: &blocks)
        return blocks
    }

    /// GFM: `[ ] ` atau `[x] ` di awal paragraf pertama item menjadi status, sisanya tetap teks item.
    static func taskContent(of blocks: [MarkdownBlock]) -> (task: MarkdownTaskState?, blocks: [MarkdownBlock]) {
        guard case .paragraph(let text)? = blocks.first else { return (nil, blocks) }
        let prefix = String(text.characters.prefix(MarkdownSyntax.taskPrefixLength))
        guard let task = MarkdownSyntax.taskState(prefix: prefix) else { return (nil, blocks) }
        var rest = text
        let end = rest.index(rest.startIndex, offsetByCharacters: MarkdownSyntax.taskPrefixLength)
        rest.removeSubrange(rest.startIndex..<end)
        return (task, [.paragraph(rest)] + blocks.dropFirst())
    }
}

// MARK: - Helpers

private extension MarkdownParser {
    /// Spasi yang menempel pada gambar tidak bermakna lagi setelah paragraf dipecah.
    static func appendParagraph(_ text: AttributedString, to blocks: inout [MarkdownBlock]) {
        var trimmed = text
        while trimmed.characters.first?.isWhitespace == true {
            trimmed.characters.removeFirst()
        }
        while trimmed.characters.last?.isWhitespace == true {
            trimmed.characters.removeLast()
        }
        if !trimmed.characters.isEmpty {
            blocks.append(.paragraph(trimmed))
        }
    }
}
