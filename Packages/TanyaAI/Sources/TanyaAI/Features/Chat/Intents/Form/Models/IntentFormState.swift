//
//  IntentFormState.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

import Foundation

/// State bersama per instance form, untuk disimpan pemilik sesi di luar sel table.
/// Tidak memegang service, sheet, atau aturan validasi khusus satu intent.
struct IntentFormState<FieldID: Hashable> {
    let fields: [FormField<FieldID>]
    private(set) var values: [FieldID: FormFieldValue] = [:]
    private(set) var invalidFieldIDs: Set<FieldID> = []

    init(fields: [FormField<FieldID>]) {
        self.fields = fields
        refreshValues()
    }

    var visibleFields: [FormField<FieldID>] { fields.filter { values[$0.id] != nil } }

    var firstInvalidChoiceID: FieldID? {
        for field in fields where invalidFieldIDs.contains(field.id) {
            switch field.initialValue {
            case .singleSelection, .multipleSelection:
                return field.id
            default:
                continue
            }
        }
        return nil
    }

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

    /// Dipanggil pemakai ketika Konfirmasi. Urutan definisi menentukan pilihan kosong paling atas.
    mutating func validate() -> Bool {
        invalidFieldIDs = invalidRequiredFields()
        return invalidFieldIDs.isEmpty
    }

    mutating func reset() {
        values = [:]
        invalidFieldIDs = []
        refreshValues()
    }
}

// MARK: - Helpers

private extension IntentFormState {
    /// Hanya field terlihat yang mempunyai nilai draft. Field yang tampil kembali memakai nilai awalnya,
    /// sehingga input lama yang sudah disembunyikan tidak terbawa ke permintaan berikutnya.
    mutating func refreshValues() {
        let previous = values
        var visibleValues: [FieldID: FormFieldValue] = [:]
        for field in fields {
            visibleValues[field.id] = resolvedValue(for: field.id, source: previous, visited: [])
        }
        values = visibleValues
    }

    func resolvedValue(
        for fieldID: FieldID,
        source: [FieldID: FormFieldValue],
        visited: Set<FieldID>
    ) -> FormFieldValue? {
        guard !visited.contains(fieldID), let field = fields.first(where: { $0.id == fieldID }) else { return nil }
        var path = visited
        path.insert(fieldID)
        if let condition = field.condition {
            guard let parent = resolvedValue(for: condition.fieldID, source: source, visited: path),
                parent == condition.value
            else { return nil }
        }
        return normalizedValue(source[fieldID] ?? field.initialValue, for: field)
    }

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

    func invalidRequiredFields() -> Set<FieldID> {
        var invalid: Set<FieldID> = []
        for field in fields where field.isRequired && field.isEnabled {
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
