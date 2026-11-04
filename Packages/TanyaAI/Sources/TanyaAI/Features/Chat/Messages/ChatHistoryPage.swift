//
//  ChatHistoryPage.swift
//  TanyaAI
//
//  Created by Wendra on 4/11/26.
//

import Foundation

/// Satu halaman history siap tampil. Puluhan jawaban panjang dalam satu halaman bisa terasa bila di-decode dan
/// di-parse sebagai Markdown di main actor, jadi `decoded(from:)` mengerjakannya di background.
struct ChatHistoryPage: Sendable {
    let messages: [ChatMessage]
    let nextBefore: String?

    init(data: Data) throws {
        let page = try JSONDecoder.wire.decode(WireEnvelope<WireHistoryPage>.self, from: data).data
        messages = page.messages.compactMap(ChatMessage.init(wire:))
        nextBefore = page.nextBefore
    }

    static func decoded(from data: Data) async throws -> ChatHistoryPage {
        try await Task.detached(priority: .userInitiated) {
            try ChatHistoryPage(data: data)
        }.value
    }
}
