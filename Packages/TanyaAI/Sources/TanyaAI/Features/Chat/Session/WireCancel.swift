//
//  WireCancel.swift
//  TanyaAI
//
//  Created by Wendra on 30/10/26.
//

/// `data` 200 `POST /chat/conversations/{id}/cancel`. True = turn yang berjalan dibatalkan; pembuka kunci
/// tetap `turn_end {"status":"canceled"}` di stream. False = tidak ada turn aktif (no-op).
struct WireCancel: Decodable {
    let isCanceled: Bool

    private enum CodingKeys: String, CodingKey {
        case isCanceled = "canceled"
    }
}
