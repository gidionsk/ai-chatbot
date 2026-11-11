//
//  ConversationState.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

/// `data.state` dari `/v1/chat/init`. Nilai baru dari server dibaca sebagai `unknown`, bukan gagal decode.
enum ConversationState: String, Decodable {
    case assistantActive = "ASSISTANT_ACTIVE"
    case agentQueued = "AGENT_QUEUED"
    case agentActive = "AGENT_ACTIVE"
    case closed = "CLOSED"
    case unknown

    /// Nasabah menunggu atau dilayani agen manusia: kirim tidak memakai turn lock dan `turn_end` (contract §7.5).
    var isLiveAgent: Bool { self == .agentQueued || self == .agentActive }

    init(from decoder: Decoder) throws {
        self = Self(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .unknown
    }
}
