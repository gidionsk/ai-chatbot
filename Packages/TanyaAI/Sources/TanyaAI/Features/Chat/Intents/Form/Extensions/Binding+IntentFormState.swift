//
//  Binding+IntentFormState.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import SwiftUI

/// Semua perubahan UI melewati API mutasi state; setter values/error tetap private milik model.
@MainActor
extension Binding {
    func formValue<FieldID>(for fieldID: FieldID) -> Binding<FormFieldValue?>
    where Value == IntentFormState<FieldID> {
        Binding<FormFieldValue?>(
            get: { wrappedValue.value(for: fieldID) },
            set: { value in
                guard let value else { return }
                var state = wrappedValue
                state.update(value, for: fieldID)
                wrappedValue = state
            }
        )
    }

    func confirmForm<FieldID>(onInvalidChoice: (FieldID) -> Void, onValid: () -> Void)
    where Value == IntentFormState<FieldID> {
        var state = wrappedValue
        let isValid = state.validate()
        wrappedValue = state
        if isValid {
            onValid()
            return
        }
        if let fieldID = state.firstInvalidChoiceID { onInvalidChoice(fieldID) }
    }

    func resetForm<FieldID>(onCancel: () -> Void) where Value == IntentFormState<FieldID> {
        var state = wrappedValue
        state.reset()
        wrappedValue = state
        onCancel()
    }

    func selectFormOptions<FieldID>(_ codes: [String], for fieldID: FieldID)
    where Value == IntentFormState<FieldID> {
        let value = formValue(for: fieldID)
        switch value.wrappedValue {
        case .singleSelection:
            value.wrappedValue = .singleSelection(codes.first)
        case .multipleSelection:
            value.wrappedValue = .multipleSelection(codes)
        default:
            return
        }
    }
}
