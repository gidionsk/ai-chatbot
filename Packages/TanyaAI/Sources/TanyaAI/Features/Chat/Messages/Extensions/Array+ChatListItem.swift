//
//  Array+ChatListItem.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

import Foundation

extension Array where Element == ChatListItem {
    /// Baris percakapan kronologis dengan chip tanggal per hari. Pesan yang tidak punya tampilan tidak ikut, supaya
    /// tidak memunculkan chip tanpa isi. Id ganda dibuang karena diffable data source crash bila menerimanya, sedangkan
    /// id pesan berasal dari server.
    init(rows: [ChatRow], calendar: Calendar = .current) {
        self.init()
        var seenIDs = Set<String>()
        let visibleRows = rows.filter { $0.isVisible && seenIDs.insert($0.id).inserted }
        for day in visibleRows.groupedByDay(calendar: calendar) {
            if day.date != nil {
                append(.date(day.id, isSpaced: !isEmpty))
            }
            for row in day.rows {
                append(.message(row, isSpaced: !isEmpty))
            }
        }
    }
}
