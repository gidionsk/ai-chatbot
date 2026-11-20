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
    var referenceLetter: ReferenceLetterForm?
    var isReferenceLetterEnabled = false
    var onSheet: (ChatBottomSheet) -> Void = { _ in }

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
            VStack(alignment: .leading, spacing: FigmaSize.spacingLarge.scaledToArtwork) {
                MessageRow(row: row, onOpenLink: actions.onOpenLink)
                if isReferenceLetterEnabled, case .message(let message) = row,
                    message.intent == .referenceLetter, message.author == .assistant, message.status == .active
                {
                    referenceLetterCard(for: message)
                }
            }
        case .followUps(let questions, let isEnabled):
            FollowUpsSection(questions: questions, isEnabled: isEnabled, onSelect: actions.onSelectFollowUp)
        case .liveAgentNotice(let notice):
            LiveAgentNoticeCard(kind: notice.kind)
        case .leaveAgentQueue(let isEnabled):
            FilledButton(
                title: String(ChatCopy.leaveAgentQueue, locale: locale),
                variant: .link,
                onTap: actions.onLeaveAgentQueue
            )
            .disabled(!isEnabled)
            .accessibilityIdentifier(ChatElementIdentifier.leaveAgentQueue)
        case .agentTyping:
            AgentTypingIndicator()
        case .content:
            VStack(spacing: .zero) { content }
        }
    }
}

// MARK: - Helpers

private extension ChatListRow {
    @ViewBuilder
    func referenceLetterCard(for message: ChatMessage) -> some View {
        if let referenceLetter, message.successID == nil || referenceLetter.receipt != nil {
            ReferenceLetterCard(form: referenceLetter, messageID: message.id, onSheet: onSheet)
        } else {
            ReferenceLetterCard.status(
                copy: message.successID == nil ? .referenceLetterHistory : .referenceLetterComplete,
                locale: locale
            )
        }
    }

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
