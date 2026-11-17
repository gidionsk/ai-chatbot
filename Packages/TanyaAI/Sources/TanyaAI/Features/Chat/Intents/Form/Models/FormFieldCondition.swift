//
//  FormFieldCondition.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

/// Satu dependensi field: tampil ketika field induk yang terlihat mempunyai nilai ini.
struct FormFieldCondition<FieldID: Hashable> {
    let fieldID: FieldID
    let value: FormFieldValue
}
