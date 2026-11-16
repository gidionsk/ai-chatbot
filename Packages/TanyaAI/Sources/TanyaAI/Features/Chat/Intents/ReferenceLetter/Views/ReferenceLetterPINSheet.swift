//
//  ReferenceLetterPINSheet.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import DesignKit
import SwiftUI

@MainActor
struct ReferenceLetterPINSheet: View {
    @Environment(\.locale) private var locale
    @ObservedObject var session: ReferenceLetterSession
    let onClose: () -> Void
    let onProcessing: (Bool) -> Void

    var body: some View {
        VStack(spacing: FigmaSize.spacingMedium.scaledToArtwork) {
            TransactionPINEntry(
                prompt: String(ChatCopy.referencePINPrompt, locale: locale),
                deleteLabel: String(ChatCopy.referencePINDelete, locale: locale),
                progressLabel: String(ChatCopy.referencePINProgress, locale: locale),
                error: session.errorMessage ?? fallbackError
            ) { pin in
                onProcessing(true)
                Task {
                    await session.submit(pin: pin)
                    // Verifikasi fixture/cache bisa selesai tanpa frame `.verifying`; jangan bergantung onChange.
                    onProcessing(session.phase.isBusy)
                    if [.completed, .editing, .cancelled, .uncertain].contains(session.phase) { onClose() }
                }
            }
            .disabled(session.phase != .awaitingPIN)
            if session.phase.isBusy { LoadingIndicator() }
            if session.phase == .blocked {
                FilledButton(title: String(ChatCopy.referenceClose, locale: locale), onTap: onClose)
                    .padding(FigmaSize.spacingLarge.scaledToArtwork)
            }
        }
    }
}

// MARK: - Helpers

private extension ReferenceLetterPINSheet {
    var fallbackError: String? {
        guard session.failure != nil else { return nil }
        return String(ChatCopy.referenceVerificationFailed, locale: locale)
    }
}
