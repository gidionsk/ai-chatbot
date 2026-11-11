//
//  ChatIntentTests.swift
//  TanyaAITests
//
//  Created by Wendra on 10/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

/// `intent` dari gateway ikut ke pesan: nilai dikenal menjadi case, kosong menjadi nil, nilai baru tidak gagal decode.
struct ChatIntentTests {
    @Test(
        arguments: [
            ("handover-to-agent", ChatIntent.liveAgent),
            ("portfolio-summary", .unknown),
            ("", nil)
        ] as [(String, ChatIntent?)])
    func messageCarriesTheGatewayIntent(wire: String, expected: ChatIntent?) throws {
        let data = Data(WireFixture.message(seq: 2, direction: "assistant", intent: wire).utf8)
        let message = try #require(ChatMessage(wire: JSONDecoder.wire.decode(WireMessage.self, from: data)))
        #expect(message.intent == expected)
        #expect(message.text == "pesan 2")
    }

    /// Pesan tanpa field `intent` (mis. dari kanal lain) tetap terbaca.
    @Test
    func missingIntentIsNil() throws {
        let data = Data(#"{"message_id":"m-1","seq":"1","direction":"agent","payload":"Halo","status":"active"}"#.utf8)
        let message = try #require(ChatMessage(wire: JSONDecoder.wire.decode(WireMessage.self, from: data)))
        #expect(message.intent == nil)
    }
}
