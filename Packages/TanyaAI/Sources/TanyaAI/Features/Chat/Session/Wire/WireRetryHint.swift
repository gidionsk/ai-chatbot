//
//  WireRetryHint.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

/// `data` pada error 429 `rate_limited` dan 503 `capacity_full`.
struct WireRetryHint: Decodable {
    let retryAfterMs: Int?
}
