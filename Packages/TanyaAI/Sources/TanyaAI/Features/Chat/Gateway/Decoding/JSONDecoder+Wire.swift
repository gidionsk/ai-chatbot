//
//  JSONDecoder+Wire.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation

extension JSONDecoder {
    /// Decoder untuk body chat-gateway: key snake_case (`message_id`) menjadi camelCase (`messageId`).
    static var wire: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}
