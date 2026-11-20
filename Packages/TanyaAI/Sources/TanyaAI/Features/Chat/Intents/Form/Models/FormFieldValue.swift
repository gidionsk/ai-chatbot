//
//  FormFieldValue.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

/// Nilai draft form. Jenis nilai sekaligus menentukan jenis input, tanpa tipe UI atau data PIN.
enum FormFieldValue: Hashable {
    case text(String)
    case singleSelection(String?)
    case multipleSelection([String])
    case toggle(Bool)
}
