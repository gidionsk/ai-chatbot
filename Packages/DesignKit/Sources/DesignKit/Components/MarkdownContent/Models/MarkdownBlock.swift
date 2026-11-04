//
//  MarkdownBlock.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import Foundation

/// Satu blok Markdown hasil parser Apple, siap dirender. Teks inline masih membawa `inlinePresentationIntent`
/// dan `link`; style diterapkan saat render agar mengikuti palette dan font pemakai.
enum MarkdownBlock: Equatable {
    case paragraph(AttributedString)
    /// Level 1 = `#`.
    case heading(level: Int, text: AttributedString)
    case list(MarkdownList)
    case quote([MarkdownBlock])
    /// Isi code block apa adanya, tanpa baris kosong di awal/akhir.
    case code(String)
    case divider
    case table(MarkdownTable)
}
