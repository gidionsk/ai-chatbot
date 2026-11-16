//
//  TextInputField.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI
import UIKit

/// Field teks satu baris dengan label di atas dan `error` merah di bawah. `placeholder` digambar sendiri supaya
/// warnanya sama dengan field pilihan. Nonaktif lewat `.disabled(...)` dari pemakai: latar abu-abu dan tidak bisa
/// diketik; isinya tetap terbaca.
@MainActor
public struct TextInputField: View {
    @Environment(\.designColors) private var colors
    @Binding private var text: String
    private let label: String?
    private let placeholder: String
    private let error: String?
    private let keyboard: UIKeyboardType

    public init(
        label: String? = nil,
        text: Binding<String>,
        placeholder: String,
        error: String? = nil,
        keyboard: UIKeyboardType = .default
    ) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.error = error
        self.keyboard = keyboard
    }

    public var body: some View {
        FieldFrame(label: label, error: error) {
            ZStack(alignment: .leading) {
                hint
                input
            }
            .fieldBox(isInvalid: error != nil)
        }
    }

    @ViewBuilder
    private var hint: some View {
        if text.isEmpty {
            Text(placeholder)
                .designFont(.field)
                .foregroundColor(colors.colorsTextSecondary)
                .lineLimit(CustomTextLines.fieldInput)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        }
    }

    private var input: some View {
        TextField(String(), text: $text)
            .designFont(.field)
            .foregroundColor(colors.colorsTextPrimaryDark)
            .keyboardType(keyboard)
            .accessibilityLabel(label ?? placeholder)
    }
}
