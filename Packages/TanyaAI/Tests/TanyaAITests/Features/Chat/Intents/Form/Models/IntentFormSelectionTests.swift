//
//  IntentFormSelectionTests.swift
//  TanyaAITests
//
//  Created by Wendra on 17/11/26.
//

import Testing

@testable import TanyaAI

struct IntentFormSelectionTests {
    @Test
    func singleChoiceOnlyKeepsACodeFromItsOptions() {
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .firstChoice, initialValue: .singleSelection(nil), options: options)
        ])
        state.update(.singleSelection("b"), for: .firstChoice)
        #expect(state.value(for: .firstChoice) == .singleSelection("b"))
        state.update(.singleSelection("missing"), for: .firstChoice)
        #expect(state.value(for: .firstChoice) == .singleSelection(nil))
    }

    @Test
    func multipleChoiceRemovesUnknownAndDuplicateCodesInHostOrder() {
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .firstChoice, initialValue: .multipleSelection([]), options: options)
        ])
        state.update(.multipleSelection(["b", "missing", "b", "a"]), for: .firstChoice)
        #expect(state.value(for: .firstChoice) == .multipleSelection(["a", "b"]))
        state.update(.multipleSelection([]), for: .firstChoice)
        #expect(state.value(for: .firstChoice) == .multipleSelection([]))
    }

    @Test
    func duplicateAndEmptyOptionCodesDoNotDuplicateTheStoredSelection() {
        let choices = [
            FormOption(code: "", title: "Missing code"),
            FormOption(code: "a", title: "First"),
            FormOption(code: "a", title: "Duplicate")
        ]
        let state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .firstChoice, initialValue: .multipleSelection(["a", ""]), options: choices)
        ])
        #expect(state.value(for: .firstChoice) == .multipleSelection(["a"]))
    }

    @Test
    func inputWithTheWrongKindOrAnUnknownFieldDoesNotReplaceDraftValues() {
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .requiredText, initialValue: .text("Keep this"))
        ])
        state.update(.toggle(true), for: .requiredText)
        state.update(.text("Unknown field"), for: .childText)
        #expect(state.value(for: .requiredText) == .text("Keep this"))
        #expect(state.value(for: .childText) == nil)
    }
}

// MARK: - Helpers

private extension IntentFormSelectionTests {
    var options: [FormOption] {
        [FormOption(code: "a", title: "First"), FormOption(code: "b", title: "Second")]
    }
}
