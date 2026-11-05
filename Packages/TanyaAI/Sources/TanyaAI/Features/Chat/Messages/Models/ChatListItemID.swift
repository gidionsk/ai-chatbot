//
//  ChatListItemID.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

/// Identitas baris table. Pesan memakai id-nya sendiri; baris lain hanya ada satu per daftar, kecuali chip tanggal.
enum ChatListItemID: Hashable {
    case welcome
    case date(ChatDayID)
    case message(String)
    case followUps
    case content
}
