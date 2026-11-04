//
//  MarkdownList.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

/// List bullet atau bernomor; item bisa berisi paragraf, list bertingkat, atau blok lain.
struct MarkdownList: Equatable {
    let isOrdered: Bool
    let items: [MarkdownListItem]

    /// Nomor terbesar: penandanya paling lebar dan menentukan lebar kolom penanda.
    var largestOrdinal: Int {
        items.map(\.ordinal).max() ?? MarkdownSyntax.firstOrdinal
    }
}
