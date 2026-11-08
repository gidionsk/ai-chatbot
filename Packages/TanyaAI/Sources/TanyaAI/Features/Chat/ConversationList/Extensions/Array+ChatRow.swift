//
//  Array+ChatRow.swift
//  TanyaAI
//
//  Created by Wendra on 3/11/26.
//

import Foundation

extension Array where Element == ChatRow {
    /// Kelompok per hari kalender untuk chip tanggal; urutan baris tetap kronologis. Hari berganti ke dua arah
    /// (jam perangkat bisa berbeda dengan server), jadi setiap baris tampil di bawah tanggalnya sendiri. Baris
    /// tanpa tanggal ikut hari sebelumnya. O(n): setiap baris diproses sekali dan di-append di tempat.
    func groupedByDay(calendar: Calendar = .current) -> [ChatDay] {
        var days: [ChatDay] = []
        var nextIDs: [Date?: ChatDayIdentifier] = [:]
        for row in self {
            let date = row.date.map(calendar.startOfDay(for:))
            let isNewDay = days.isEmpty || (date != nil && date != days.last?.date)
            if isNewDay {
                let id = nextIDs[date] ?? ChatDayIdentifier(date: date)
                nextIDs[date] = id.next
                days.append(ChatDay(id: id))
            }
            days[days.index(before: days.endIndex)].rows.append(row)
        }
        return days
    }
}
