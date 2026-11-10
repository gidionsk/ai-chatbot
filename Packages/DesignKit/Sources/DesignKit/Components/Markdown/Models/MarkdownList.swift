//
//  MarkdownList.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

/// List bullet atau bernomor; item bisa berisi paragraf, list bertingkat, atau blok lain.
struct MarkdownList: Equatable, Sendable {
    let isOrdered: Bool
    let items: [MarkdownListItem]
    /// Nomor terbesar: penandanya paling lebar dan menentukan lebar kolom penanda. Dihitung sekali per list,
    /// bukan per baris, dan tidak dipakai list bullet.
    let largestOrdinal: Int

    init(isOrdered: Bool, items: [MarkdownListItem]) {
        self.isOrdered = isOrdered
        self.items = items
        largestOrdinal = (isOrdered ? items.map(\.ordinal).max() : nil) ?? MarkdownSyntax.firstOrdinal
    }
}
