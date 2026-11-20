//
//  FormFieldValue+Selection.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

extension FormFieldValue {
    var selectedCodes: [String] {
        switch self {
        case .singleSelection(let code):
            return code.map { [$0] } ?? []
        case .multipleSelection(let codes):
            return codes
        case .text, .toggle:
            return []
        }
    }
}
