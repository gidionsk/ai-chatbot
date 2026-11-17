//
//  IntentFormState.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

/// State bersama per instance form, untuk disimpan pemilik sesi di luar sel table.
/// Tidak memegang service, sheet, atau aturan validasi khusus satu intent.
struct IntentFormState<FieldID: Hashable> {
    let fields: [FormField<FieldID>]
    var values: [FieldID: FormFieldValue] = [:]
    var invalidFieldIDs: Set<FieldID> = []

    init(fields: [FormField<FieldID>]) {
        self.fields = fields
        refreshValues()
    }

    var visibleFields: [FormField<FieldID>] { fields.filter { values[$0.id] != nil } }

    func value(for fieldID: FieldID) -> FormFieldValue? { values[fieldID] }

    /// Perubahan input tidak menambah error baru; hanya membersihkan error lama yang sudah teratasi.
    mutating func update(_ value: FormFieldValue, for fieldID: FieldID) {
        guard let field = fields.first(where: { $0.id == fieldID }), field.isEnabled,
            values[fieldID] != nil, let normalized = normalizedValue(value, for: field)
        else { return }
        values[fieldID] = normalized
        refreshValues()
        invalidFieldIDs.formIntersection(invalidRequiredFields())
    }

    mutating func reset() {
        values = [:]
        invalidFieldIDs = []
        refreshValues()
    }
}
