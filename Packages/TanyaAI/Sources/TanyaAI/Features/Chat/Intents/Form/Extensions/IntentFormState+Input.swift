//
//  IntentFormState+Input.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

extension IntentFormState {
    /// Dipakai lewat `$state[text: id]`; penulisan tetap melewati normalisasi dan validasi di update.
    subscript(text fieldID: FieldID) -> String {
        get {
            guard case .text(let text) = values[fieldID] else { return String() }
            return text
        }
        set { update(.text(newValue), for: fieldID) }
    }

    subscript(toggle fieldID: FieldID) -> Bool {
        get {
            guard case .toggle(let isOn) = values[fieldID] else { return false }
            return isOn
        }
        set { update(.toggle(newValue), for: fieldID) }
    }

    /// Hasil sheet pilihan. Jenis nilai field menentukan satu atau banyak; field non-pilihan diabaikan.
    mutating func select(_ codes: [String], for fieldID: FieldID) {
        switch values[fieldID] {
        case .singleSelection:
            update(.singleSelection(codes.first), for: fieldID)
        case .multipleSelection:
            update(.multipleSelection(codes), for: fieldID)
        default:
            return
        }
    }
}
