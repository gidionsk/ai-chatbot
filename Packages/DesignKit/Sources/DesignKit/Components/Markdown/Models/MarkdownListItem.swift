//
//  MarkdownListItem.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

/// Satu item list. `ordinal` dari parser (list bernomor bisa mulai dari angka selain 1).
struct MarkdownListItem: Equatable, Sendable {
    let ordinal: Int
    let blocks: [MarkdownBlock]
    /// Nil untuk item list biasa.
    var task: MarkdownTaskState?
}
