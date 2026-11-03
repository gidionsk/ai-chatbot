//
//  MarkdownDocument.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

/// Markdown yang sudah di-parse sekali dengan parser Apple (`AttributedString(markdown:)`: CommonMark + tabel
/// GFM). Parse saat data datang, bukan setiap render. HTML tampil sebagai teks dan gambar sebagai teks alt.
public struct MarkdownDocument: Equatable {
    let blocks: [MarkdownBlock]

    public init(_ markdown: String) {
        blocks = MarkdownParser.blocks(from: markdown)
    }
}
