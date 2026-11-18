//
//  LiveAgentNoticeCard.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

import DesignKit
import SwiftUI

/// Status live agent di antara pesan: chip awal/akhir sesi, kartu (antre, selesai, batal, agen tidak tersedia), atau
/// chip lalu kartu untuk sesi yang berakhir (Figma frame 62/64 dan `time_stamp`).
@MainActor
struct LiveAgentNoticeCard: View {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors
    let kind: LiveAgentNoticeKind

    var body: some View {
        VStack(spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            chip
            card
        }
    }

    @ViewBuilder
    private var chip: some View {
        if let text = kind.chip {
            DateChip(text: String(text, locale: locale), style: .filled)
                .accessibilityIdentifier(ChatElementIdentifier.liveAgentChip)
        }
    }

    @ViewBuilder
    private var card: some View {
        if let copy = kind.card {
            NoticeCard(title: String(copy.title, locale: locale), message: String(copy.message, locale: locale)) {
                Image(DesignIcon.headset).resizable().scaledToFit()
                    .foregroundColor(colors.colorsIconDark)
            }
            .accessibilityIdentifier(ChatElementIdentifier.liveAgentNotice)
        }
    }
}
