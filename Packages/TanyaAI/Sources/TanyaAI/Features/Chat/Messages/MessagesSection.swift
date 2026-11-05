//
//  MessagesSection.swift
//  TanyaAI
//
//  Created by Wendra on 2/11/26.
//

import DesignKit
import SwiftUI

/// Daftar pesan di area scroll `ScreenContainer`, kronologis, dengan chip tanggal di atas pesan pertama setiap
/// hari. Pertanyaan nasabah = bubble merah (gagal kirim: abu-abu dengan hint); jawaban bot = Markdown tanpa
/// background; agen = teks polos tanpa background. Link di jawaban diteruskan ke host.
/// `VStack`, bukan `LazyVStack`: pada `LazyVStack` berbaris tidak seragam, `scrollTo` membuat update SwiftUI berputar
/// tanpa henti dan posisi baris hanya perkiraan. Biaya layout naik mengikuti jumlah pesan, jadi saat paging history
/// ditambahkan harus diganti list ber-recycle (lihat `docs/REVAMP_NOTES.md`). TODO: List ber-recycle menyusul.
@MainActor
struct MessagesSection: View {
    @Environment(\.locale)
    private var locale
    private let days: [ChatDay]
    private let latestQuestionID: String?
    private let onOpenLink: (URL) -> Void

    /// Pesan yang tidak punya tampilan (payload non-teks, pengirim tidak dikenal) tidak ikut, supaya tidak
    /// memunculkan chip tanggal tanpa isi.
    init(rows: [ChatRow], onOpenLink: @escaping (URL) -> Void) {
        days = rows.filter(\.isVisible).groupedByDay()
        latestQuestionID = rows.last(where: \.isQuestion)?.id
        self.onOpenLink = onOpenLink
    }

    var body: some View {
        VStack(spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            ForEach(days) { day in
                dateChip(for: day)
                ForEach(day.rows) { row in
                    bubble(for: row)
                        .background(alignment: .top) { scrollMarker(for: row) }
                        .anchorPreference(key: ChatQuestionTopKey.self, value: .top) {
                            row.id == latestQuestionID ? $0 : nil
                        }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(ChatElementIdentifier.messages)
    }
}

// MARK: - Helpers

private extension MessagesSection {
    /// Target `scrollTo` di tepi atas pertanyaan. Tanpa tinggi, karena `scrollTo` ikut menghitung tinggi target, dan
    /// dengan id sendiri, karena `scrollTo` ke id baris mengenai baris `ForEach`, bukan penanda ini.
    @ViewBuilder
    func scrollMarker(for row: ChatRow) -> some View {
        if row.id == latestQuestionID {
            Color.clear
                .frame(height: .zero)
                .accessibilityHidden(true)
                .id(ChatElementIdentifier.parking)
        }
    }

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
        if let document = message.document {
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
