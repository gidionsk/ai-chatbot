//
//  AgentSessionBanner.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

import DesignKit
import SwiftUI

/// Bar hitam di bawah header selama dilayani agen (Figma node 3262-86657): "You're now in mode talking with CA" dan
/// End Session yang memanggil `leave-agent`, sama dengan Batalkan di kartu antre.
@MainActor
struct AgentSessionBanner: View {
    @Environment(\.locale) private var locale
    let onEnd: () -> Void

    var body: some View {
        ActionBanner(
            text: String(ChatCopy.agentSessionBanner, locale: locale),
            actionTitle: String(ChatCopy.endAgentSession, locale: locale),
            onAction: onEnd
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(ChatElementIdentifier.agentSessionBanner)
    }
}
