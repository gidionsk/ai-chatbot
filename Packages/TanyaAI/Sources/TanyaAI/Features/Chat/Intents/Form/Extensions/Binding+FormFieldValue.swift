//
//  Binding+FormFieldValue.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import SwiftUI

@MainActor
extension Binding where Value == FormFieldValue? {
    var formText: Binding<String> {
        Binding<String>(
            get: {
                guard case .text(let text) = wrappedValue else { return String() }
                return text
            },
            set: { wrappedValue = .text($0) }
        )
    }

    var formToggle: Binding<Bool> {
        Binding<Bool>(
            get: {
                guard case .toggle(let isOn) = wrappedValue else { return false }
                return isOn
            },
            set: { wrappedValue = .toggle($0) }
        )
    }
}
