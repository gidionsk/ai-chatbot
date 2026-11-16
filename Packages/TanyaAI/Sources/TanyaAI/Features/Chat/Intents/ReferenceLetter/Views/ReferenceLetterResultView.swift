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
            NoticeCard(title: String(ChatCopy.referenceTitle, locale: locale), message: message) {
                Image(systemName: ReferenceLetterSymbols.receipt)
            }
            .accessibilityIdentifier(ChatElementIdentifier.referenceResult)

        }
    }
}

// MARK: - Helpers

private extension ReferenceLetterResultView {
    var message: String {
        switch session.phase {
        case .cancelled:
            return String(ChatCopy.referenceCancelled, locale: locale)
        default:
            return String(ChatCopy.referenceHistory, locale: locale)
        }
    }
}
