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
    private(set) var values: [FieldID: FormFieldValue] = [:]
    private(set) var invalidFieldIDs: Set<FieldID> = []

    init(fields: [FormField<FieldID>]) {
        self.fields = fields
        values = refreshedValues()
    }

    var visibleFields: [FormField<FieldID>] { fields.filter { values[$0.id] != nil } }

    func value(for fieldID: FieldID) -> FormFieldValue? { values[fieldID] }

    /// Perubahan input tidak menambah error baru; hanya membersihkan error lama yang sudah teratasi.
    mutating func update(_ value: FormFieldValue, for fieldID: FieldID) {
        guard let field = fields.first(where: { $0.id == fieldID }), field.isEnabled,
            values[fieldID] != nil, let normalized = normalizedValue(value, for: field)
        else { return }
        values[fieldID] = normalized
        values = refreshedValues()
        invalidFieldIDs.formIntersection(invalidRequiredFields())
    }

    /// Dipanggil pemakai ketika Konfirmasi. Urutan definisi menentukan pilihan kosong paling atas.
    mutating func validate() -> Bool {
        invalidFieldIDs = invalidRequiredFields()
        return invalidFieldIDs.isEmpty
    }

    mutating func reset() {
        values = [:]
        invalidFieldIDs = []
        values = refreshedValues()
    }
}
