//
//  ChatListRow.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

import DesignKit
import SwiftUI

/// Isi satu baris table percakapan. Margin horizontal dan jarak antarbaris milik baris ini.
@MainActor
struct ChatListRow<Content: View>: View {
    @Environment(\.locale) private var locale
    let item: ChatListItem
    let welcome: WelcomeContent?
    let content: Content
    let actions: ChatRowActions

    var body: some View {
        rowContent
            .frame(maxWidth: .infinity)
            .padding(.horizontal, FigmaSize.spacingLarge.scaledToArtwork)
            .padding(.top, item.topSpacing)
    }

    @ViewBuilder
    private var rowContent: some View {
        switch item {
        case .welcome(let isEnabled):
            welcomeSection(isEnabled: isEnabled)
        case .date(let day, _):
            dateChip(day)
        case .message(let row, _):
            MessageRow(row: row, onOpenLink: actions.onOpenLink)
        case .followUps(let questions, let isEnabled):
            FollowUpsSection(questions: questions, isEnabled: isEnabled, onSelect: actions.onSelectFollowUp)
        case .liveAgentNotice(let notice, let isLeaveEnabled):
            LiveAgentNoticeCard(kind: notice.kind, isLeaveEnabled: isLeaveEnabled, onLeave: actions.onLeaveAgentQueue)
        case .agentTyping:
            // TODO: Desain indikator mengetik belum ada di Figma; sementara teks miring tanpa ikon.
            StatusCaption(text: String(ChatCopy.liveAgentTyping, locale: locale), isItalic: true)
                .accessibilityIdentifier(ChatElementIdentifier.agentTyping)
        case .answerLoading:
            answerLoading
        case .content:
            VStack(spacing: .zero) { content }
        }
    }
}

// MARK: - Status

private extension ChatListRow {
    /// Titik berdenyut tanpa teks selama bot menyiapkan jawaban, supaya layar tidak terkesan diam; copy hanya untuk
    /// VoiceOver.
    var answerLoading: some View {
        TypingDots()
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement()
            .accessibilityLabel(String(ChatCopy.answerLoading, locale: locale))
            .accessibilityIdentifier(ChatElementIdentifier.answerLoading)
    }
}

// MARK: - Helpers

private extension ChatListRow {
    @ViewBuilder
    func welcomeSection(isEnabled: Bool) -> some View {
        if let welcome {
            WelcomeSection(
                content: welcome, isEnabled: isEnabled, onSelect: actions.onSelectShortcut,
                onOpenLink: actions.onOpenLink
            )
        }
    }

    @ViewBuilder
    func dateChip(_ day: ChatDayIdentifier) -> some View {
        if let date = day.date {
            TextChip(text: ChatDateFormat.dayLabel(for: date, locale: locale))
                .accessibilityIdentifier(ChatElementIdentifier.dateChip)
        }
    }
}
