//
//  ChatDay.swift
//  TanyaAI
//
//  Created by Wendra on 3/11/26.
//

import Foundation

/// Baris pada satu hari kalender (zona waktu perangkat); chip tanggal tampil di atasnya.
struct ChatDay: Identifiable, Equatable {
    /// Awal hari; nil bila baris pertama tidak punya tanggal (tanpa chip).
    let date: Date?
    let rows: [ChatRow]

    /// Awal hari, bukan id baris pertama: bubble lokal yang diganti salinan stream tidak membuat ulang chip.
    /// Unik karena hari hanya maju (`groupedByDay`).
    var id: Date? { date }
}
