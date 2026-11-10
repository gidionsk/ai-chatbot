//
//  FollowUpsSection.swift
//  TanyaAI
//
//  Created by Wendra on 4/11/26.
//

import DesignKit
import SwiftUI

/// Saran pertanyaan lanjutan di bawah jawaban terakhir, urut sesuai `follow_up_questions`. Diketuk = terkirim
/// sebagai pertanyaan, sama seperti shortcut.
@MainActor
struct FollowUpsSection: View {
    let questions: [String]
    let isEnabled: Bool
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingMedium.scaledToArtwork) {
            ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                SuggestionChip(text: question, isEnabled: isEnabled) { onSelect(question) }
                    .accessibilityIdentifier(ChatElementIdentifier.followUp(index))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, FigmaSize.spacingLarge.scaledToArtwork)
    }
}
