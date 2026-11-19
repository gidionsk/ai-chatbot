//
//  AgentSearchingIndicator.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

import DesignKit
import SwiftUI

/// "Mencari customer assistant..." di bawah pesan terakhir selama antre setelah sapaan otomatis agen.
/// TODO: Tambah ikon sparkle dan ukuran dari Figma (node 3262-86657); sementara teks saja seperti indikator mengetik.
@MainActor
struct AgentSearchingIndicator: View {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors

    var body: some View {
        Text(String(ChatCopy.liveAgentSearching, locale: locale))
            .designFont(.caption)
            .foregroundColor(colors.colorsTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityIdentifier(ChatElementIdentifier.agentSearching)
    }
}
