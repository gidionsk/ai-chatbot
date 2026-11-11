//
//  WireStateChange.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

/// `data` event SSE `state` (contract §5). Hanya state tujuan yang dipakai; `from` dan nama agen belum dipakai.
struct WireStateChange: Decodable {
    let nextState: ConversationState

    private enum CodingKeys: String, CodingKey {
        case nextState = "to"
    }
}
