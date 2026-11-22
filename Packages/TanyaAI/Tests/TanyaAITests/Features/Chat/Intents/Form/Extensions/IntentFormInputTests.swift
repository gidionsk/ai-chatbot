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
        var state = IntentFormState<TestFormFieldID>(
            rules: .fixed([
                FormField(id: .requiredText, initialValue: .text("Initial"), isRequired: true),
                FormField(id: .toggle, initialValue: .toggle(false))
            ]))
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
        var state = IntentFormState(rules: MockLetterFormRules.rules)
        state[text: .email] = "Ignored"
        state[text: .address] = "Hidden"
        state[text: .format] = "Wrong kind"
        state[toggle: .email] = true
        #expect(state[text: .address].isEmpty)
        #expect(!state[toggle: .email])
        #expect(state.value(for: .email) == .text("stored@example.test"))
        #expect(state.value(for: .address) == nil)
        #expect(state.value(for: .format) == .singleSelection("softcopy"))
    }

    @Test
    func optionCallbacksUseTheFieldKindAndNormalizeAgainstHostChoices() {
        let options = [FormOption(code: "01", title: "First"), FormOption(code: "02", title: "Second")]
        var state = IntentFormState<TestFormFieldID>(
            rules: .fixed([
                FormField(id: .firstChoice, initialValue: .singleSelection(nil), options: options),
                FormField(id: .secondChoice, initialValue: .multipleSelection([]), options: options),
                FormField(id: .requiredText, initialValue: .text("Text"))
            ]))
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
