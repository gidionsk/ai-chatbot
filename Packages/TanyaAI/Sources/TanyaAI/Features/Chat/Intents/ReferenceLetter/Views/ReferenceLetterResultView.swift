//
//  ReferenceLetterResultView.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import DesignKit
import SwiftUI

@MainActor
struct ReferenceLetterResultView: View {
    @Environment(\.locale) private var locale
    @ObservedObject var session: ReferenceLetterSession

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            if let introduction = session.inquiry?.introduction {
                Text(introduction).designFont(.body)
            }
            NoticeCard(title: title, message: message) {
                Image(systemName: ReferenceLetterSymbols.receipt)
            }
            .accessibilityIdentifier(ChatElementIdentifier.referenceResult)
            if let receipt = session.receipt {
                Text(receipt.message).designFont(.body)
                    .accessibilityIdentifier(ChatElementIdentifier.referenceReceiptMessage)
            }
        }
    }
}

// MARK: - Helpers

private extension ReferenceLetterResultView {
    var title: String {
        guard let title = session.receipt?.title, !title.isEmpty else {
            return String(ChatCopy.referenceTitle, locale: locale)
        }
        return title
    }

    var message: String {
        switch session.phase {
        case .completed:
            return String(
                format: String(ChatCopy.referenceCompleted, locale: locale), session.submittedPurpose ?? String()
            )
        case .cancelled:
            return String(ChatCopy.referenceCancelled, locale: locale)
        default:
            return String(ChatCopy.referenceHistory, locale: locale)
        }
    }
}
