//
//  IntentFormRules+Fixture.swift
//  TanyaAITests
//
//  Created by Wendra on 19/11/26.
//

@testable import TanyaAI

extension IntentFormRules {
    /// Fixture untuk test input/validasi yang tidak membutuhkan aturan dinamis.
    static func fixed(_ fields: [FormField<FieldID>]) -> Self {
        Self(fields: { _ in fields }, fieldsToReset: { _ in [] })
    }
}
