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
    @Environment(\.designColors) private var colors
    @ObservedObject var form: ReferenceLetterForm
    let messageID: String
    let onSheet: (ChatBottomSheet) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            if let receipt = form.receipt {
                Self.status(title: receipt.title, copy: .referenceLetterComplete, locale: locale)
                    .accessibilityIdentifier(ChatElementIdentifier.referenceLetterSuccess)
                if !receipt.message.isEmpty {
                    Text(receipt.message)
                        .designFont(.body)
                        .foregroundColor(colors.colorsTextPrimaryDark)
                }
            } else if form.isCancelled {
                Self.status(copy: .referenceLetterCancelled, locale: locale)
            } else if let inquiry = form.inquiry {
                if !inquiry.introduction.isEmpty {
                    Text(inquiry.introduction)
                        .designFont(.body)
                        .foregroundColor(colors.colorsTextPrimaryDark)
                }
                fields
            } else if form.isInquiryFailed {
                FilledButton(title: String(ChatCopy.referenceLetterRetry, locale: locale), variant: .outlined) {
                    Task { await form.load() }
                }
            } else {
                LoadingIndicator()
            }
        }
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
