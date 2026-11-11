//
//  LiveAgentMessageRow.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

import DesignKit
import SwiftUI

/// Pesan agen manusia: avatar dan label pengirim statis di atas teks (Figma frame 68). Teks agen tidak diproses
/// sebagai Markdown.
@MainActor
struct LiveAgentMessageRow: View {
    @Environment(\.locale) private var locale
    let text: String

    var body: some View {
        SenderMessageCard(sender: String(ChatCopy.liveAgentSender, locale: locale), text: text) {
            // TODO: Ganti dengan avatar live agent dari Figma; sementara memakai orb Tanya AI.
            Image(ChatImage.welcomeOrb).resizable().scaledToFill()
        }
        .accessibilityIdentifier(ChatElementIdentifier.agentMessage)
    }
}
