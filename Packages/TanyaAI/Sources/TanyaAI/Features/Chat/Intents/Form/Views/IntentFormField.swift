//
//  IntentFormField.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import DesignKit
import SwiftUI

/// Satu field merender komponen DesignKit sesuai jenis nilainya, tanpa menyimpan draft kedua.
@MainActor
struct IntentFormField<FieldID: Hashable>: View {
    @Binding var state: IntentFormState<FieldID>
    let fieldID: FieldID
    let presentation: FormFieldPresentation
    let selectionText: String?
    let error: String?
    let onOpenChoices: () -> Void

    var body: some View {
        switch state.value(for: fieldID) {
        case .text:
            TextInputField(
                label: presentation.label,
                text: $state[text: fieldID],
                placeholder: presentation.placeholder,
                error: error,
                keyboard: presentation.keyboard
            )
        case .singleSelection, .multipleSelection:
            SelectField(
                label: presentation.label,
                value: selectionText,
                placeholder: presentation.placeholder,
                error: error,
                onTap: onOpenChoices
            )
        case .toggle:
            ToggleRow(label: presentation.label, isOn: $state[toggle: fieldID])
        case nil:
            EmptyView()
        }
    }
}
