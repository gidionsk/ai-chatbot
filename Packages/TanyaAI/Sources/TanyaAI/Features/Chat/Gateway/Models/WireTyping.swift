//
//  WireTyping.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

import Foundation

/// `data` event SSE `typing` (contract §5): sinyal sementara, tidak tersimpan dan tidak di-replay.
struct WireTyping: Decodable {
    let direction: ChatAuthor
    let isTyping: Bool
    /// Batas tampil indikator bila tidak ada kabar baru (`ttl_s`).
    let lifetimeSeconds: TimeInterval?

    private enum CodingKeys: String, CodingKey {
        case direction
        case isTyping = "typing"
        // Decoder `.wire` mengubah `ttl_s` menjadi `ttlS` sebelum dicocokkan.
        case lifetimeSeconds = "ttlS"
    }
}
