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
        var pass = Int.zero
        var largestFieldCount = Int.zero
        while true {
            let fields = rules.fields(candidate)
            // Pakai draft asli setiap putaran agar default sementara bisa mengikuti aturan terbaru.
            let refreshed = refreshedValues(for: fields)
            largestFieldCount = max(largestFieldCount, fields.count)
            // Aturan yang sama dengan input yang sama menghasilkan field yang sama.
            guard refreshed != candidate, pass < largestFieldCount else { return (fields, refreshed) }
            candidate = refreshed
            pass = (Int.zero..<largestFieldCount).index(after: pass)
        }
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
