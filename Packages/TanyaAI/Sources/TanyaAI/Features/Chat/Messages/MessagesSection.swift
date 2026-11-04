//
//  MessagesSection.swift
//  TanyaAI
//
//  Created by Wendra on 2/11/26.
//

import DesignKit
import SwiftUI

/// Bubble pertanyaan nasabah di area scroll `ScreenContainer`, kronologis, dengan chip tanggal di atas pesan
/// pertama setiap hari. Pertanyaan yang gagal dikirim tampil abu-abu dengan hint di bawahnya.
/// TODO: Bubble bot dan list ber-recycle menyusul di PR daftar pesan; saat itu pengelompokan memakai semua baris.
@MainActor
struct MessagesSection: View {
    @Environment(\.locale)
    private var locale
    private let days: [ChatDay]

    /// Hanya baris yang tampil yang dikelompokkan, supaya hari berisi pesan bot saja tidak memunculkan chip kosong.
    init(rows: [ChatRow]) {
        days = rows.filter(\.isQuestion).groupedByDay()
    }

    var body: some View {
        LazyVStack(spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            ForEach(days) { day in
                dateChip(for: day)
                ForEach(day.rows) { row in
                    bubble(for: row)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(ChatElementIdentifier.messages)
    }
}

// MARK: - Helpers

private extension MessagesSection {
    @ViewBuilder
    func dateChip(for day: ChatDay) -> some View {
        if let date = day.date {
            DateChip(text: ChatDateFormat.dayLabel(for: date, locale: locale))
                .accessibilityIdentifier(ChatElementIdentifier.dateChip)
        }
    }

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
