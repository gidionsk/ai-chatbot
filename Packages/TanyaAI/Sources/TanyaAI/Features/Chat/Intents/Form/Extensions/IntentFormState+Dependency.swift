//
//  IntentFormState+Dependency.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

extension IntentFormState {
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
}
