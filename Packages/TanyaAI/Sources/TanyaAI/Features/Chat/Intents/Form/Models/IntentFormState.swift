//
//  IntentFormState.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

/// State bersama per instance form, untuk disimpan pemilik sesi di luar sel table.
/// Tidak memegang service, sheet, atau aturan validasi khusus satu intent.
struct IntentFormState<FieldID: Hashable> {
    private let rules: IntentFormRules<FieldID>
    private(set) var fields: [FormField<FieldID>]
    private(set) var values: [FieldID: FormFieldValue] = [:]
    private(set) var invalidFieldIDs: Set<FieldID> = []

    init(rules: IntentFormRules<FieldID>) {
        self.rules = rules
        fields = rules.fields([:])
        values = refreshedValues(for: fields)
    }

    var visibleFields: [FormField<FieldID>] { fields }

    func value(for fieldID: FieldID) -> FormFieldValue? { values[fieldID] }

    /// Perubahan input tidak menambah error baru; hanya membersihkan error lama yang sudah teratasi.
    mutating func update(_ value: FormFieldValue, for fieldID: FieldID) {
        guard let field = fields.first(where: { $0.id == fieldID }), field.isEnabled,
            let previous = values[fieldID], let normalized = normalizedValue(value, for: field)
        else { return }
        values[fieldID] = normalized
        if normalized != previous {
            let resetIDs = Set(rules.fieldsToReset(fieldID))
            for field in fields where resetIDs.contains(field.id) {
                values[field.id] = field.initialValue
            }
        }
        fields = rules.fields(values)
        values = refreshedValues(for: fields)
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
        fields = rules.fields(values)
        values = refreshedValues(for: fields)
    }
}
