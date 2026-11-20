//
//  IntentFormState+Rules.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

extension IntentFormState {
    /// Hanya field yang dikembalikan aturan mempunyai nilai. Field yang muncul kembali memakai nilai awal;
    /// pilihan lama dibuang bila tidak tersedia lagi dalam opsi terbaru.
    func refreshedValues(for fields: [FormField<FieldID>]) -> [FieldID: FormFieldValue] {
        var refreshed: [FieldID: FormFieldValue] = [:]
        for field in fields {
            refreshed[field.id] =
                normalizedValue(values[field.id] ?? field.initialValue, for: field)
                ?? normalizedValue(field.initialValue, for: field)
        }
        return refreshed
    }
}
