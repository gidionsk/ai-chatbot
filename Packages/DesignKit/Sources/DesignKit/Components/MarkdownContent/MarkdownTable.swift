//
//  MarkdownTable.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import Foundation

/// Tabel GFM. Setiap baris punya jumlah sel sama dengan `alignments`; sel yang hilang diisi teks kosong.
struct MarkdownTable: Equatable, Sendable {
    let alignments: [MarkdownColumnAlignment]
    /// Kosong bila tabel tanpa baris header.
    let header: [AttributedString]
    let rows: [[AttributedString]]

    /// Baris ringkasan: hanya sel pertama dan terakhir yang berisi, jadi label total boleh melewati kolom tengah.
    /// GFM tidak punya colspan; payload menulisnya dengan sel tengah kosong (`| Total | | +3.600.000 |`).
    func isSummaryRow(_ cells: [AttributedString]) -> Bool {
        let middle = cells.dropFirst().dropLast()
        let isFirstFilled = cells.first?.characters.isEmpty == false
        let isLastFilled = cells.last?.characters.isEmpty == false
        return !middle.isEmpty && isFirstFilled && isLastFilled && middle.allSatisfy(\.characters.isEmpty)
    }
}
