//
//  ReferenceLetterCard.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

import DesignKit
import SwiftUI

@MainActor
struct ReferenceLetterCard: View {
    @Environment(\.locale) private var locale
    @ObservedObject var form: ReferenceLetterForm
    let messageID: String
    let onSheet: (ChatSheet) -> Void
    let onOpenLink: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            if let receipt = form.receipt {
                Self.status(title: receipt.title, copy: .referenceLetterComplete, locale: locale)
                    .accessibilityIdentifier(ChatElementIdentifier.referenceLetterSuccess)
                if let document = form.acknowledgement {
                    MarkdownContent(document: document, onOpenLink: onOpenLink)
                }
            } else if form.layout == .cancelled {
                Self.status(copy: .referenceLetterCancelled, locale: locale)
                    .accessibilityIdentifier(ChatElementIdentifier.referenceLetterCancelled)
            } else if case .form = form.layout {
                if let document = form.introduction {
                    MarkdownContent(document: document, onOpenLink: onOpenLink)
                }
                fields
            } else if form.layout == .loading {
                loading
            }
        }
    }

    /// Titik yang sama dengan loading jawaban bot, karena form adalah lanjutan jawaban itu.
    private var loading: some View {
        TypingDots()
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement()
            .accessibilityLabel(String(ChatCopy.answerLoading, locale: locale))
            .accessibilityIdentifier(ChatElementIdentifier.referenceLetterLoading)
    }

    private var fields: some View {
        IntentFormView(
            state: $form.draft,
            title: String(ChatCopy.referenceLetterTitle, locale: locale),
            confirmLabel: String(ChatCopy.referenceLetterConfirm, locale: locale),
            cancelLabel: String(ChatCopy.referenceLetterCancel, locale: locale),
            presentation: presentation(for:),
            selectionSummary: selectionSummary(for:options:),
            onOpenChoices: { onSheet(.referenceLetterChoices(messageID: messageID, field: $0)) },
            onConfirm: {
                form.clearSubmissionError()
                onSheet(.referenceLetterPIN(messageID: messageID))
            },
            onCancel: form.cancel
        )
        .accessibilityIdentifier(ChatElementIdentifier.referenceLetterForm)
    }

    static func status(
        title: String = String(),
        copy: ChatCopy,
        locale: Locale
    ) -> some View {
        NoticeCard(
            title: title.isEmpty ? String(ChatCopy.referenceLetterTitle, locale: locale) : title,
            message: String(copy, locale: locale)
        ) {
            Image(DesignIcon.checkmark).resizable().scaledToFit()
        }
    }
}

private extension ReferenceLetterCard {
    func presentation(for field: ReferenceLetterFieldID) -> FormFieldPresentation {
        FormFieldPresentation(
            label: String(field.label, locale: locale),
            placeholder: String(ChatCopy.referenceLetterChoose, locale: locale),
            requiredError: String(ChatCopy.referenceLetterRequired, locale: locale)
        )
    }

    func selectionSummary(for field: ReferenceLetterFieldID, options: [FormOption]) -> String {
        if field == .accounts, !options.dropFirst().isEmpty {
            return String(
                format: String(ChatCopy.referenceLetterAccountCount, locale: locale),
                locale: locale,
                options.count
            )
        }
        return options.first?.title ?? String()
    }
}
