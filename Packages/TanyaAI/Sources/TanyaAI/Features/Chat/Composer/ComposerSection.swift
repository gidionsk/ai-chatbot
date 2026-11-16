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
    @Environment(\.locale) private var locale
    @State private var draft = String()
    private let isEnabled: Bool
    private let phase: ChatTurnPhase
    private let onSend: (String) -> Bool
    private let onStop: () -> Void
    private let onAttach: (() -> Void)?
    private let onTyping: ((Bool) -> Void)?

    /// `onSend` true = bubble pertanyaan tampil, draft langsung dikosongkan. Selama menunggu jawaban nasabah boleh
    /// mengetik pertanyaan berikutnya, tetapi harus menekan stop (atau menunggu jawaban selesai) untuk mengirimnya.
    /// `onAttach` nil = tombol lampiran tidak tampil. `onTyping` dipanggil setiap draft berubah: true = draft berisi,
    /// false = kosong atau composer hilang; draft sendiri tetap lokal.
    init(
        isEnabled: Bool, phase: ChatTurnPhase, onSend: @escaping (String) -> Bool,
        onStop: @escaping () -> Void, onAttach: (() -> Void)? = nil, onTyping: ((Bool) -> Void)? = nil
    ) {
        self.isEnabled = isEnabled
        self.phase = phase
        self.onSend = onSend
        self.onStop = onStop
        self.onAttach = onAttach
        self.onTyping = onTyping
    }

    var body: some View {
        VStack(spacing: .zero) {
            divider
            MessageComposer(
                text: $draft, placeholder: String(ChatCopy.placeholder, locale: locale),
                actionLabel: String(actionCopy, locale: locale),
                isEnabled: isEnabled, action: action, attachment: attachment, onSend: submit, onStop: onStop
            )
            .padding(FigmaSize.spacingLarge.scaledToArtwork)
        }
        .onChange(of: draft) { onTyping?(!$0.isEmpty) }
        .onDisappear { onTyping?(false) }
    }

    /// Garis selebar layar di atas composer (Figma), memisahkan area chat dari input.
    private var divider: some View {
        SeparatorLine()
    }
}

// MARK: - Helpers

private extension ComposerSection {
    var attachment: MessageComposerAttachment? {
        let label = String(ChatCopy.liveAgentAttachment, locale: locale)
        return onAttach.map { MessageComposerAttachment(label: label, onTap: $0) }
    }

    var action: MessageComposerAction {
        switch phase {
        case .idle:
            return .send
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
        case .awaitingReply, .canceling:
            return .stop
        }
    }
}

// MARK: - Actions

private extension ComposerSection {
    func submit() {
        guard onSend(draft) else { return }
        draft = String()
    }
}
