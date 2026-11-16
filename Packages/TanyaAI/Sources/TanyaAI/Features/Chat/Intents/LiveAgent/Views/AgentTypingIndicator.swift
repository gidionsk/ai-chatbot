//
//  AgentTypingIndicator.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

import DesignKit
import SwiftUI

/// "Agen sedang mengetik..." miring di bawah pesan terakhir. TODO: Ganti dengan desain indikator dari Figma.
@MainActor
struct AgentTypingIndicator: View {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors

    var body: some View {
        Text(String(ChatCopy.liveAgentTyping, locale: locale))
            .designFont(.captionItalic)
            .foregroundColor(colors.colorsTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier(ChatElementIdentifier.agentTyping)
    }
}
