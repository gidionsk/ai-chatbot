//
//  MarkdownTable.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import Foundation

/// Tabel GFM. Setiap baris punya jumlah sel sama dengan `alignments`; sel yang hilang diisi teks kosong.
struct MarkdownTable: Equatable {
    let alignments: [MarkdownColumnAlignment]
    /// Kosong bila tabel tanpa baris header.
    let header: [AttributedString]
    let rows: [[AttributedString]]
}
