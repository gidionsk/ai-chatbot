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
        case .history, .cancelled:
            ReferenceLetterResultView(session: session)
        case .editing:
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
                onOpenOptions: onOpenSheet
            )
            .disabled(session.phase != .editing)
            if session.phase == .editing {
                FilledButton(title: String(ChatCopy.referenceCancel, locale: locale), variant: .outlined) {
                    session.cancel()
                }
            }
        }
    }

}
