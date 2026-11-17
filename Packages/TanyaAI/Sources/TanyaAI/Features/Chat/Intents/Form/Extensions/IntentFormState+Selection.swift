//
//  IntentFormState+Selection.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

extension IntentFormState {
    func normalizedValue(_ value: FormFieldValue, for field: FormField<FieldID>) -> FormFieldValue? {
        switch (field.initialValue, value) {
        case (.text, .text), (.toggle, .toggle):
            return value
        case (.singleSelection, .singleSelection(let code)):
            guard let code, !code.isEmpty, field.options.contains(where: { $0.code == code }) else {
                return .singleSelection(nil)
            }
            return .singleSelection(code)
        case (.multipleSelection, .multipleSelection(let codes)):
            var selected = Set(codes)
            let ordered = field.options.compactMap { option -> String? in
                guard !option.code.isEmpty, selected.remove(option.code) != nil else { return nil }
                return option.code
            }
            return .multipleSelection(ordered)
        default:
            return nil
        }
    }
}
