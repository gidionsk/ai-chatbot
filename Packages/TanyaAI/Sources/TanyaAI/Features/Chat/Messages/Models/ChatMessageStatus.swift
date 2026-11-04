//
//  ChatMessageStatus.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

/// `canceled` = tombstone pesan nasabah yang turn-nya dibatalkan; dikirim ulang dengan `message_id` yang sama.
enum ChatMessageStatus: String, Decodable {
    case active, canceled, unknown

    init(from decoder: Decoder) throws {
        self = Self(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .unknown
    }
}
