//
//  IntentFormView.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import DesignKit
import SwiftUI

/// Kartu form bersama. Pemilik menyimpan state per instance dan memasang bottom sheet di root halaman.
@MainActor
struct IntentFormView<FieldID: Hashable>: View {
    @Environment(\.designColors) private var colors
    @Binding var state: IntentFormState<FieldID>
    let title: String
    let confirmLabel: String
    let cancelLabel: String
    let presentation: (FieldID) -> FormFieldPresentation
    let selectionSummary: (FieldID, [FormOption]) -> String
    let onOpenChoices: (FieldID) -> Void
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            Text(title)
                .designFont(.cardTitle)
                .foregroundColor(colors.colorsTextPrimaryDark)
                .accessibilityAddTraits(.isHeader)
            ForEach(state.visibleFields, id: \.id) { field in
                IntentFormField(
                    state: $state,
                    fieldID: field.id,
                    presentation: presentation(field.id),
                    selectionText: selectionText(for: field),
                    error: state.invalidFieldIDs.contains(field.id) ? presentation(field.id).requiredError : nil,
                    onOpenChoices: { onOpenChoices(field.id) }
                )
                .disabled(!field.isEnabled)
            }
            actions
        }
        .padding(FigmaSize.spacingLarge.scaledToArtwork)
        .cardStyle(isOutlined: false)
    }

    private var actions: some View {
        HStack(spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            FilledButton(title: cancelLabel, variant: .outlined, onTap: cancel)
            FilledButton(title: confirmLabel, onTap: confirm)
        }
    }
}

// MARK: - Helpers

private extension IntentFormView {
    func selectionText(for field: FormField<FieldID>) -> String? {
        let codes = Set(state.value(for: field.id)?.selectedCodes ?? [])
        let options = field.options.filter { codes.contains($0.code) }
        guard !options.isEmpty else { return nil }
        return selectionSummary(field.id, options)
    }
}

// MARK: - Actions

extension IntentFormView {
    /// Error ditulis dulu agar tetap tampil saat sheet pilihan kosong pertama terbuka.
    func confirm() {
        guard state.validate() else {
            state.firstInvalidChoiceID.map(onOpenChoices)
            return
        }
        onConfirm()
    }

    /// Draft kembali ke nilai awal sebelum pemilik diberi tahu.
    func cancel() {
        state.reset()
        onCancel()
    }
}
