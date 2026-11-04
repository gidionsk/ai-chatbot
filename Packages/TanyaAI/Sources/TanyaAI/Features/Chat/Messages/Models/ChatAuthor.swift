//
//  ChatAuthor.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

/// `direction` pesan: nasabah, bot, atau agen manusia. Nilai baru dari server menjadi `unknown`.
enum ChatAuthor: String, Decodable {
    case customer, bot, agent, unknown

    init(from decoder: Decoder) throws {
        self = Self(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .unknown
    }
}
