//
//  LiveAgentNoticeCard.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

import DesignKit
import SwiftUI

/// Kartu status live agent: antre, selesai, batal, atau agen tidak tersedia (Figma frame 62/64).
@MainActor
struct LiveAgentNoticeCard: View {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors
    let kind: LiveAgentNoticeKind

    var body: some View {
        NoticeCard(title: String(kind.title, locale: locale), message: String(kind.message, locale: locale)) {
            Image(DesignIcon.headset).resizable().scaledToFit()
                .foregroundColor(colors.colorsIconDark)
        }
        .accessibilityIdentifier(ChatElementIdentifier.liveAgentNotice)
    }
}
