//
//  IntentFormRules.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

/// Aturan satu intent form, ditulis di folder intent; mesin bersama memanggilnya setiap ada perubahan nilai.
struct IntentFormRules<FieldID: Hashable> {
    /// Field yang berlaku untuk nilai saat ini, urut dari atas ke bawah. Mesin mengisi default dari `initialValue`.
    /// Aturan harus menghasilkan daftar yang sama untuk input yang sama.
    let fields: ([FieldID: FormFieldValue]) -> [FormField<FieldID>]
    /// Anak langsung yang di-reset ketika nilai induk berubah. Mesin mengikuti seluruh turunannya.
    let fieldsToReset: (FieldID) -> [FieldID]
}
