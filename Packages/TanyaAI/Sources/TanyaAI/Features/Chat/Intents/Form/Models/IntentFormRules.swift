//
//  IntentFormRules.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

/// Aturan satu intent form, ditulis di folder intent; mesin bersama memanggilnya setiap ada perubahan nilai.
struct IntentFormRules<FieldID: Hashable> {
    /// Field yang berlaku untuk nilai saat ini, urut dari atas ke bawah. Draft kosong saat init/reset.
    let fields: ([FieldID: FormFieldValue]) -> [FormField<FieldID>]
    /// Field yang kembali ke nilai awal setelah field ini diganti ke nilai yang berbeda.
    let fieldsToReset: (FieldID) -> [FieldID]
}
