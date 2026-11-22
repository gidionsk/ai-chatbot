//
//  LiveAgentNoticeCard.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

import DesignKit
import SwiftUI

/// Kartu status live agent di antara pesan (Figma frame 62/64 dan node 3262-86657): antre, terhubung, selesai, batal,
/// atau agen tidak tersedia. Agen bergabung tidak punya kartu sendiri. Kartu antre membawa tombol batal di dalam
/// kartu, di bawah garis pemisah (Figma node 1903-8266).
@MainActor
struct LiveAgentNoticeCard: View {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors
    let kind: LiveAgentNoticeKind
    let isLeaveEnabled: Bool
    let onLeave: () -> Void

    @ViewBuilder
    var body: some View {
        if let copy = kind.card {
            card(copy)
                .accessibilityIdentifier(ChatElementIdentifier.liveAgentNotice)
        }
    }

    @ViewBuilder
    private func card(_ copy: (title: ChatCopy, message: ChatCopy)) -> some View {
        let title = String(copy.title, locale: locale)
        let message = String(copy.message, locale: locale)
        switch kind {
        case .connecting:
            NoticeCard(title: title, message: message) {
                icon
            } action: {
                leaveButton
            }
        default:
            NoticeCard(title: title, message: message) { icon }
        }
    }

    private var icon: some View {
        Image(DesignIcon.headset).resizable().scaledToFit()
            .foregroundColor(colors.colorsIconDark)
    }

    private var leaveButton: some View {
        FilledButton(title: String(ChatCopy.leaveAgentQueue, locale: locale), variant: .outlined, onTap: onLeave)
            .disabled(!isLeaveEnabled)
            .accessibilityIdentifier(ChatElementIdentifier.leaveAgentQueue)
    }
}
