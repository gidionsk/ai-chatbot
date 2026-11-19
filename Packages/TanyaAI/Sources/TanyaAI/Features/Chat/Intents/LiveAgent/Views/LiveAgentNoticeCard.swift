//
//  LiveAgentNoticeCard.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

import DesignKit
import SwiftUI

/// Kartu status live agent di antara pesan (Figma frame 62/64 dan node 3262-86657): antre, terhubung, selesai, batal,
/// atau agen tidak tersedia. Agen bergabung tidak punya kartu sendiri.
@MainActor
struct LiveAgentNoticeCard: View {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors
    let kind: LiveAgentNoticeKind

    @ViewBuilder
    var body: some View {
        if let copy = kind.card {
            NoticeCard(title: String(copy.title, locale: locale), message: String(copy.message, locale: locale)) {
                Image(DesignIcon.headset).resizable().scaledToFit()
                    .foregroundColor(colors.colorsIconDark)
            }
            .accessibilityIdentifier(ChatElementIdentifier.liveAgentNotice)
        }
    }
}
