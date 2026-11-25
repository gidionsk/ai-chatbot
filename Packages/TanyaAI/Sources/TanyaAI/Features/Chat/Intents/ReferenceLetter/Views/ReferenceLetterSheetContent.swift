//
//  ReferenceLetterSheetContent.swift
//  TanyaAI
//
//  Created by Wendra on 22/11/26.
//

import DesignKit
import SwiftUI

@MainActor
struct ReferenceLetterSheetContent: View {
    @Environment(\.locale) private var locale
    @ObservedObject var form: ReferenceLetterForm
    @Binding var activeSheet: ChatSheet?
    @State private var pin = String()
    @State private var acknowledgementError: Error?
    let item: ChatSheet
    let isSubmitting: Bool
    let onSubmit: (String) async throws -> Bool

    init(
        form: ReferenceLetterForm,
        activeSheet: Binding<ChatSheet?>,
        item: ChatSheet,
        isSubmitting: Bool,
        onSubmit: @escaping (String) async throws -> Bool
    ) {
        _form = ObservedObject(wrappedValue: form)
        _activeSheet = activeSheet
        self.item = item
        self.isSubmitting = isSubmitting
        self.onSubmit = onSubmit
    }

    var body: some View {
        switch item {
        case .attachment, .leaveAgent:
            EmptyView()
        case .referenceLetterChoices(_, let field):
            IntentFormOptions(
                state: $form.draft,
                fieldID: field,
                title: String(field.label, locale: locale),
                confirmLabel: String(ChatCopy.referenceLetterChoose, locale: locale),
                onSelect: { activeSheet = nil }
            )
        case .referenceLetterPIN:
            PinEntry(
                title: String(ChatCopy.referenceLetterPIN, locale: locale),
                pin: $pin,
                length: ReferenceLetterPIN.length,
                error: errorText,
                deleteLabel: String(ChatCopy.referenceLetterDeleteDigit, locale: locale),
                onComplete: complete
            )
            .disabled(isSubmitting)
            .onChange(of: pin.isEmpty) { isEmpty in
                if !isEmpty { form.clearSubmissionError() }
            }
            .onDisappear(perform: didClosePIN)
        }
    }
}

private extension ReferenceLetterSheetContent {
    var errorText: String? {
        guard case .pinVerification(let message) = form.pinError else { return nil }
        return message ?? String(ChatCopy.referenceLetterSubmitFailed, locale: locale)
    }

    func complete(_ value: String) {
        pin = String()
        Task {
            do {
                let isSubmitted = try await onSubmit(value)
                if isSubmitted, activeSheet == item { activeSheet = nil }
            } catch {
                guard activeSheet == item else { return }
                acknowledgementError = acknowledgementCause(of: error)
                activeSheet = nil
            }
        }
    }

    func acknowledgementCause(of error: Error) -> Error {
        if case .acknowledgement(let cause) = error as? ReferenceLetterSubmissionError { return cause }
        return error
    }

    func didClosePIN() {
        pin = String()
        guard let error = acknowledgementError else { return }
        acknowledgementError = nil
        form.presentAcknowledgementError(error)
    }
}
