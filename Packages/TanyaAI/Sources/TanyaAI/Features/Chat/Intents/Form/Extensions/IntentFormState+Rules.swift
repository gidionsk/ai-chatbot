//
//  IntentFormState+Rules.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

extension IntentFormState {
    func resetDescendants(of fieldID: FieldID, using rules: IntentFormRules<FieldID>) -> Set<FieldID> {
        var visited: Set<FieldID> = [fieldID]
        var pending = rules.fieldsToReset(fieldID)
        while let child = pending.popLast() {
            guard visited.insert(child).inserted else { continue }
            pending.append(contentsOf: rules.fieldsToReset(child))
        }
        visited.remove(fieldID)
        return visited
    }

    func resolvedForm(using rules: IntentFormRules<FieldID>) -> (
        fields: [FormField<FieldID>], values: [FieldID: FormFieldValue]
    ) {
        var candidate = values
        var seen: Set<[FieldID: FormFieldValue]> = []
        var fields: [FormField<FieldID>] = []
        // Draft berulang menandakan hasil stabil atau aturan yang berputar.
        while seen.insert(candidate).inserted {
            fields = rules.fields(candidate)
            // Pakai draft asli setiap putaran agar default sementara bisa mengikuti aturan terbaru.
            candidate = refreshedValues(for: fields)
        }
        return (fields, candidate)
    }
}

// MARK: - Helpers

private extension IntentFormState {
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
