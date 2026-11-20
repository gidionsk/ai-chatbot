//
//  FormFieldPresentation.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import UIKit

/// Copy dan keyboard dari pemakai UI; bukan bagian kontrak data service host.
struct FormFieldPresentation {
    let label: String
    let placeholder: String
    let requiredError: String
    let keyboard: UIKeyboardType

    init(
        label: String,
        placeholder: String = String(),
        requiredError: String,
        keyboard: UIKeyboardType = .default
    ) {
        self.label = label
        self.placeholder = placeholder
        self.requiredError = requiredError
        self.keyboard = keyboard
    }
}
