//
//  IntentFormInputTests.swift
//  TanyaAITests
//
//  Created by Wendra on 18/11/26.
//

import Testing

@testable import TanyaAI

struct IntentFormInputTests {
    @Test
    func typedInputsReadCurrentStateAndWriteThroughItsUpdateAPI() {
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .requiredText, initialValue: .text("Initial"), isRequired: true),
            FormField(id: .toggle, initialValue: .toggle(false))
        ])
        #expect(state[text: .requiredText] == "Initial")
        #expect(!state[toggle: .toggle])
        state[text: .requiredText] = String()
        let isValid = state.validate()
        #expect(!isValid)
        #expect(state.invalidFieldIDs == [.requiredText])
        state[text: .requiredText] = "Edited"
        state[toggle: .toggle] = true
        #expect(state.value(for: .requiredText) == .text("Edited"))
        #expect(state.value(for: .toggle) == .toggle(true))
        #expect(state.invalidFieldIDs.isEmpty)
        state.reset()
        #expect(state[text: .requiredText] == "Initial")
        #expect(!state[toggle: .toggle])
    }

    @Test
    func disabledHiddenAndMismatchedInputsCannotChangeState() {
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .disabledText, initialValue: .text("Stored"), isEnabled: false),
            FormField(id: .parentToggle, initialValue: .toggle(false)),
            FormField(
                id: .childText,
                initialValue: .text(String()),
                condition: FormFieldCondition(fieldID: .parentToggle, value: .toggle(true))
            )
        ])
        state[text: .disabledText] = "Ignored"
        state[text: .childText] = "Hidden"
        state[text: .parentToggle] = "Wrong kind"
        state[toggle: .disabledText] = true
        #expect(state[text: .childText].isEmpty)
        #expect(!state[toggle: .disabledText])
        #expect(state.value(for: .disabledText) == .text("Stored"))
        #expect(state.value(for: .childText) == nil)
        #expect(state.value(for: .parentToggle) == .toggle(false))
    }

    @Test
    func optionCallbacksUseTheFieldKindAndNormalizeAgainstHostChoices() {
        let options = [FormOption(code: "01", title: "First"), FormOption(code: "02", title: "Second")]
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .firstChoice, initialValue: .singleSelection(nil), options: options),
            FormField(id: .secondChoice, initialValue: .multipleSelection([]), options: options),
            FormField(id: .requiredText, initialValue: .text("Text"))
        ])
        state.select(["02", "01"], for: .firstChoice)
        state.select(["02", "unknown", "01", "02"], for: .secondChoice)
        state.select(["01"], for: .requiredText)
        #expect(state.value(for: .firstChoice) == .singleSelection("02"))
        #expect(state.value(for: .secondChoice) == .multipleSelection(["01", "02"]))
        #expect(state.value(for: .requiredText) == .text("Text"))
        state.select([], for: .firstChoice)
        state.select([], for: .secondChoice)
        #expect(state.value(for: .firstChoice) == .singleSelection(nil))
        #expect(state.value(for: .secondChoice) == .multipleSelection([]))
    }
}
