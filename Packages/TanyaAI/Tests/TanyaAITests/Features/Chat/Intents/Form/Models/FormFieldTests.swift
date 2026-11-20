//
//  FormFieldTests.swift
//  TanyaAITests
//
//  Created by Wendra on 19/11/26.
//

import Testing

@testable import TanyaAI

struct FormFieldTests {
    @Test
    func hostOptionsKeepTheFirstOfEachCodeAndDropEmptyCodes() {
        let field = FormField<TestFormFieldID>(
            id: .firstChoice,
            initialValue: .multipleSelection([]),
            options: [
                FormOption(code: "a", title: "First"),
                FormOption(code: String(), title: "Empty"),
                FormOption(code: "a", title: "Duplicate"),
                FormOption(code: "b", title: "Second")
            ]
        )
        #expect(field.options.map(\.title) == ["First", "Second"])
    }
}
