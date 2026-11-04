//
//  ChatDayID.swift
//  TanyaAI
//
//  Created by Wendra on 4/11/26.
//

import Foundation

/// Identitas kelompok hari. Awal hari saja tidak unik: hari yang sama bisa muncul lagi bila jam perangkat
/// berbeda dengan server, jadi kemunculannya ikut dihitung.
struct ChatDayID: Hashable {
    let date: Date?
    /// Kemunculan ke berapa dari hari yang sama, mulai dari nol.
    var occurrence = Int.zero

    /// Id untuk kemunculan berikutnya dari hari yang sama.
    var next: ChatDayID {
        ChatDayID(date: date, occurrence: occurrence + 1)
    }
}
