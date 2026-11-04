//
//  ConversationState.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

/// `data.state` dari `/chat/init`. Nilai baru dari server dibaca sebagai `unknown`, bukan gagal decode.
enum ConversationState: String, Decodable {
    case botActive = "BOT_ACTIVE"
    case agentQueued = "AGENT_QUEUED"
    case agentActive = "AGENT_ACTIVE"
    case closed = "CLOSED"
    case unknown

    init(from decoder: Decoder) throws {
        self = Self(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .unknown
    }
}
