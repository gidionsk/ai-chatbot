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
    /// tanpa tanggal ikut hari sebelumnya. O(n): setiap baris diproses sekali, kelompok dibentuk saat hari berganti.
    func groupedByDay(calendar: Calendar = .current) -> [ChatDay] {
        var days: [ChatDay] = []
        var current: [ChatRow] = []
        var currentDate: Date?
        var nextIDs: [Date?: ChatDayID] = [:]

        func closeCurrentDay() {
            let id = nextIDs[currentDate] ?? ChatDayID(date: currentDate)
            nextIDs[currentDate] = id.next
            days.append(ChatDay(id: id, rows: current))
            current.removeAll(keepingCapacity: true)
        }

        for row in self {
            let date = row.date.map(calendar.startOfDay(for:))
            if !current.isEmpty, let date, date != currentDate {
                closeCurrentDay()
            }
            if current.isEmpty {
                currentDate = date
            }
            current.append(row)
        }
        if !current.isEmpty {
            closeCurrentDay()
        }
        return days
    }
}
