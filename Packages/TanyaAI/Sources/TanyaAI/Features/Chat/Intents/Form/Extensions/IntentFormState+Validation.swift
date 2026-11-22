//
//  IntentFormState+Validation.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

import Foundation

extension IntentFormState {
    var firstInvalidChoiceID: FieldID? {
        for field in visibleFields where invalidFieldIDs.contains(field.id) {
            switch field.initialValue {
            case .singleSelection, .multipleSelection:
                return field.id
            default:
                continue
            }
        }
        return nil
    }

    func invalidRequiredFields() -> Set<FieldID> {
        var invalid: Set<FieldID> = []
        for field in visibleFields where field.isRequired && field.isEnabled {
            guard let value = values[field.id] else { continue }
            if !hasRequiredValue(value) { invalid.insert(field.id) }
        }
        return invalid
    }

    func hasRequiredValue(_ value: FormFieldValue) -> Bool {
        switch value {
        case .text(let text):
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .singleSelection(let code):
            return code != nil
        case .multipleSelection(let codes):
            return !codes.isEmpty
        case .toggle:
            return true
        }
    }
}
