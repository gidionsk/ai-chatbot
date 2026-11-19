//
//  WireStateChange.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

/// `data` event SSE `state` (contract §5): state tujuan dan agen saat menuju `AGENT_ACTIVE`. `from` belum dipakai.
/// `agent` yang tidak terbaca dianggap kosong, jadi perpindahan state tetap berlaku.
struct WireStateChange: Decodable {
    let nextState: ConversationState
    let agent: WireAgent?

    private enum CodingKeys: String, CodingKey {
        case nextState = "to"
        case agent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nextState = try container.decode(ConversationState.self, forKey: .nextState)
        agent = try? container.decodeIfPresent(WireAgent.self, forKey: .agent)
    }
}
