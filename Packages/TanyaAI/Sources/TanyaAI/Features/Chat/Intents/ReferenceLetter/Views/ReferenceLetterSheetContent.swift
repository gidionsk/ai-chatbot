//
//  ReferenceLetterSheetContent.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

import DesignKit
import SwiftUI

@MainActor
struct ReferenceLetterSheetContent: View {
    @Environment(\.locale) private var locale
    @ObservedObject var form: ReferenceLetterForm
    @State private var pin = String()
    let sheet: ChatBottomSheet
    let isSubmitting: Bool
    let onClose: () -> Void
    let onSubmit: (String) -> Void

    var body: some View {
        switch sheet {
        case .attachment:
            EmptyView()
        case .referenceLetterChoices(_, let field):
            IntentFormOptions(
                state: $form.draft,
                fieldID: field,
                title: String(field.label, locale: locale),
                confirmLabel: String(ChatCopy.referenceLetterChoose, locale: locale),
                onSelect: onClose
            )
        case .referenceLetterPIN:
            PinEntry(
                title: String(ChatCopy.referenceLetterPIN, locale: locale),
                pin: $pin,
                length: ChatWire.referenceLetterPinLength,
                error: errorText,
                deleteLabel: String(ChatCopy.referenceLetterDeleteDigit, locale: locale),
                onComplete: complete
            )
            .disabled(isSubmitting)
            .onChange(of: pin.isEmpty) { isEmpty in
                if !isEmpty { form.clearSubmissionError() }
            }
            .onDisappear { pin = String() }
        }
    }
}

private extension ReferenceLetterSheetContent {
    var errorText: String? {
        guard form.isSubmissionFailed else { return nil }
        return form.submissionError ?? String(ChatCopy.referenceLetterSubmitFailed, locale: locale)
    }

    func complete(_ value: String) {
        pin = String()
        onSubmit(value)
    }
}

extension ChatScreen {
    @ViewBuilder
    func referenceLetterSheet(_ item: ChatBottomSheet) -> some View {
        if let messageID = item.referenceLetterMessageID, let form = bridge.referenceLetters[messageID] {
            ReferenceLetterSheetContent(
                form: form,
                sheet: item,
                isSubmitting: bridge.isSubmittingReferenceLetter,
                onClose: { sheet = nil },
                onSubmit: { pin in
                    Task {
                        let isSubmitted = await bridge.submitReferenceLetter(pin: pin, messageID: messageID)
                        if isSubmitted, sheet == item { sheet = nil }
                    }
                }
            )
        }
    }
}
