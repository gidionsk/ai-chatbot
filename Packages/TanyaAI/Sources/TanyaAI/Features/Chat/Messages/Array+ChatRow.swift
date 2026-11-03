//
//  Array+ChatRow.swift
//  TanyaAI
//
//  Created by Wendra on 3/11/26.
//

import Foundation

extension Array where Element == ChatRow {
    /// Kelompok per hari kalender untuk chip tanggal; urutan baris tetap kronologis. Baris tanpa tanggal, atau
    /// yang harinya mundur (jam perangkat berbeda dengan server), ikut hari sebelumnya, jadi hari hanya maju.
    /// O(n): baris di-append ke buffer hari berjalan, kelompok dibentuk sekali saat hari berganti.
    func groupedByDay(calendar: Calendar = .current) -> [ChatDay] {
        var days: [ChatDay] = []
        var current: [ChatRow] = []
        var currentDate: Date?
        for row in self {
            let date = row.date.map(calendar.startOfDay(for:))
            if !current.isEmpty, let date, date > currentDate ?? .distantPast {
                days.append(ChatDay(date: currentDate, rows: current))
                current.removeAll(keepingCapacity: true)
            }
            if current.isEmpty {
                currentDate = date
            }
            current.append(row)
        }
        if !current.isEmpty {
            days.append(ChatDay(date: currentDate, rows: current))
        }
        return days
    }
}
