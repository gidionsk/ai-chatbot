//
//  IntentFormOptions.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import DesignKit
import SwiftUI

/// Isi sheet pilihan saja. Pemilik root menutup sheet dari onSelect; daftar memakai urutan data host.
@MainActor
struct IntentFormOptions<FieldID: Hashable>: View {
    @Binding var state: IntentFormState<FieldID>
    let fieldID: FieldID
    let title: String
    let confirmLabel: String
    let onSelect: () -> Void

    var body: some View {
        if let field = state.visibleFields.first(where: { $0.id == fieldID }), let mode {
            OptionList(
                title: title,
                items: field.options.map { OptionItem(id: $0.code, title: $0.title, subtitle: $0.subtitle) },
                selectedIDs: state.value(for: fieldID)?.selectedCodes ?? [],
                mode: mode,
                confirmLabel: confirmLabel,
                isEmptyAllowed: true
            ) { codes in
                state.select(codes, for: fieldID)
                onSelect()
            }
            .disabled(!field.isEnabled)
        }
    }
}

// MARK: - Helpers

private extension IntentFormOptions {
    var mode: OptionSelectionMode? {
        switch state.value(for: fieldID) {
        case .singleSelection:
            return .single
        case .multipleSelection:
            return .multiple
        default:
            return nil
        }
    }
}
