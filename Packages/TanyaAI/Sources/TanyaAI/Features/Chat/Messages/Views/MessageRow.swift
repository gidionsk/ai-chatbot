//
//  MessageRow.swift
//  TanyaAI
//
//  Created by Wendra on 2/11/26.
//

import DesignKit
import SwiftUI

/// Satu pesan pada table percakapan. Pertanyaan nasabah = bubble merah (gagal kirim: abu-abu dengan hint); jawaban
/// bot = Markdown tanpa background; agen = kartu dengan avatar dan label pengirim. Link di jawaban diteruskan ke host.
@MainActor
struct MessageRow: View {
    @Environment(\.locale) private var locale
    let row: ChatRow
    let onOpenLink: (String) -> Void

    var body: some View {
        bubble(for: row)
    }
}

// MARK: - Helpers

private extension MessageRow {
    @ViewBuilder
    func bubble(for row: ChatRow) -> some View {
        switch row {
        case .message(let message):
            messageView(message)
        case .local(let question) where question.isFailed:
            MessageBubble(
                text: question.text, isOutgoing: true, failureNote: String(ChatCopy.sendFailed, locale: locale)
            )
            .accessibilityIdentifier(ChatElementIdentifier.failedQuestion)
        case .local(let question):
            MessageBubble(text: question.text, isOutgoing: true)
                .accessibilityIdentifier(ChatElementIdentifier.question)
        }
    }

    @ViewBuilder
    func messageView(_ message: ChatMessage) -> some View {
        if message.author == .agent, let text = message.text {
            LiveAgentMessageRow(text: text)
        } else if let document = message.document {
            MarkdownContent(document: document, onOpenLink: onOpenLink)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(ChatElementIdentifier.answer)
        } else if let text = message.text {
            MessageBubble(text: text, isOutgoing: message.author == .user)
                .accessibilityIdentifier(
                    message.author == .user ? ChatElementIdentifier.question : ChatElementIdentifier.answer
                )
        }
    }
}
