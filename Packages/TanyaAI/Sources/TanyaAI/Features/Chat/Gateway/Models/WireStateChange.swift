//
//  WireStateChange.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

/// `data` event SSE `state` (contract §5). `from` menandai akhir sesi agen; nama agen belum dipakai. `from` yang
/// tidak ada menjadi `unknown`, jadi perpindahan state tetap berlaku walau posisinya tidak tercatat.
struct WireStateChange: Decodable {
    let previousState: ConversationState
    let nextState: ConversationState

    private enum CodingKeys: String, CodingKey {
        case previousState = "from"
        case nextState = "to"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        previousState = try container.decodeIfPresent(ConversationState.self, forKey: .previousState) ?? .unknown
        nextState = try container.decode(ConversationState.self, forKey: .nextState)
    }
}
