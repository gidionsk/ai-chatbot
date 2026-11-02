//
//  MessagesSection.swift
//  TanyaAI
//
//  Created by Wendra on 2/11/26.
//

import DesignKit
import SwiftUI

/// Bubble pertanyaan nasabah di area scroll `ScreenContainer`, kronologis. Pertanyaan yang gagal dikirim tampil
/// abu-abu dengan hint di bawahnya.
/// TODO: Bubble bot, chip tanggal per hari, dan list ber-recycle menyusul di PR daftar pesan.
@MainActor
struct MessagesSection: View {
    @Environment(\.locale)
    private var locale
    private let questions: [ChatRow]

    init(rows: [ChatRow]) {
        questions = rows.filter(\.isQuestion)
    }

    var body: some View {
        LazyVStack(spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            ForEach(questions) { row in
                bubble(for: row)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(ChatElementIdentifier.messages)
    }
}

// MARK: - Helpers

private extension MessagesSection {
    @ViewBuilder
    func bubble(for row: ChatRow) -> some View {
        switch row {
        case .message(let message):
            if let text = message.text {
                MessageBubble(text: text, isOutgoing: true)
                    .accessibilityIdentifier(ChatElementIdentifier.question)
            }
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
}
