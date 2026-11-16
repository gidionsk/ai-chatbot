//
//  ReferenceLetterSessionView.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import DesignKit
import SwiftUI

@MainActor
struct ReferenceLetterSessionView: View {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors
    @ObservedObject var session: ReferenceLetterSession
    let onOpenSheet: (ReferenceLetterFieldID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            content
            message
        }
        .onChange(of: session.draft) { _ in session.clearResolvedErrors() }
    }

    @ViewBuilder
    private var content: some View {
        switch session.phase {
        case .idle, .loading:
            LoadingIndicator()
        case .loadFailed:
            Text(String(ChatCopy.referenceLoadFailed, locale: locale)).designFont(.body)
            FilledButton(title: String(ChatCopy.referenceRetry, locale: locale)) {
                Task { await session.load() }
            }
        case .history, .cancelled, .completed:
            ReferenceLetterResultView(session: session)
        case .editing, .authorizing, .submitting, .uncertain:
            form
        }
    }

    @ViewBuilder
    private var form: some View {
        if let inquiry = session.inquiry {
            ReferenceLetterForm(
                inquiry: inquiry,
                draft: $session.draft,
                invalidFields: session.invalidFields,
                onOpenOptions: onOpenSheet,
                onSubmit: session.isSubmissionAvailable ? confirm : nil
            )
            .disabled(session.phase != .editing)
            if session.phase == .editing {
                FilledButton(title: String(ChatCopy.referenceCancel, locale: locale), variant: .outlined) {
                    session.cancel()
                }
            }
        }
    }

    @ViewBuilder
    private var message: some View {
        if let message = session.errorMessage {
            Text(message).designFont(.body).foregroundColor(colors.colorsTextNegative)
        }
        if session.failure != nil {
            Text(String(ChatCopy.referenceAuthorizationFailed, locale: locale)).designFont(.body)
        }
        if session.phase.isBusy { LoadingIndicator() }
        if session.phase == .uncertain {
            Text(String(ChatCopy.referenceUncertain, locale: locale)).designFont(.body)
        }
    }
}

// MARK: - Actions

private extension ReferenceLetterSessionView {
    func confirm() {
        Task {
            await session.submit()
            if let field = ReferenceLetterFieldID.allCases.first(where: {
                $0 != .destination && session.invalidFields.contains($0)
            }) {
                onOpenSheet(field)
            }
        }
    }
}
