//
//  WireHistoryPage.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

/// `data` dari history: pesan urut `seq` menurun (terbaru dulu). `next_before` nil = tidak ada yang lebih lama.
struct WireHistoryPage: Decodable {
    let messages: [WireMessage]
    let nextBefore: String?
}
