//
//  ComposerSection.swift
//  TanyaAI
//
//  Created by Wendra on 17/10/26.
//

import DesignKit
import SwiftUI

/// Draft hidup di sini agar setiap ketikan hanya me-render composer, bukan seluruh screen/daftar pesan.
@MainActor
struct ComposerSection: View {
    @Environment(\.locale)
    private var locale
    @Environment(\.designColors)
    private var colors
    @State
    private var draft = String()
    private let isEnabled: Bool
    private let phase: ChatTurnPhase
    private let onSend: (String) async -> Bool
    private let onStop: () -> Void

    /// `onSend` true = pesan diterima; draft dikosongkan bila belum diubah selama menunggu jawaban gateway.
    /// Selama `.sending` draft dikunci; setelah pertanyaan tampil, nasabah boleh mengetik pertanyaan berikutnya
    /// tetapi harus menekan stop (atau menunggu jawaban selesai) untuk mengirimnya.
    init(
        isEnabled: Bool, phase: ChatTurnPhase, onSend: @escaping (String) async -> Bool,
        onStop: @escaping () -> Void
    ) {
        self.isEnabled = isEnabled
        self.phase = phase
        self.onSend = onSend
        self.onStop = onStop
    }

    var body: some View {
        VStack(spacing: .zero) {
            divider
            MessageComposer(
                text: $draft, placeholder: String(ChatCopy.placeholder, locale: locale),
                actionLabel: String(actionCopy, locale: locale),
                isEnabled: isEnabled, action: action, onSend: submit, onStop: onStop
            )
            .padding(FigmaSize.spacingLarge.scaledToArtwork)
        }
    }

    /// Garis selebar layar di atas composer (Figma), memisahkan area chat dari input.
    private var divider: some View {
        colors.colorsOutlineNetral
            .frame(height: FigmaSize.weightOutline.scaledToArtwork)
            .accessibilityHidden(true)
    }
}

// MARK: - Helpers

private extension ComposerSection {
    var action: MessageComposerAction {
        switch phase {
        case .idle:
            return .send
        case .sending:
            return .loading
        case .awaitingReply:
            return .stop
        case .canceling:
            return .stopping
        }
    }

    var actionCopy: ChatCopy {
        switch phase {
        case .idle:
            return .send
        case .sending:
            return .sending
        case .awaitingReply, .canceling:
            return .stop
        }
    }
}

// MARK: - Actions

private extension ComposerSection {
    func submit() {
        let text = draft
        Task {
            guard await onSend(text), draft == text else { return }
            draft = String()
        }
    }
}
