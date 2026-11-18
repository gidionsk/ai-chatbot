//
//  FormInputBindingTests.swift
//  TanyaAITests
//
//  Created by Wendra on 18/11/26.
//

import SwiftUI
import Testing

@testable import TanyaAI

@MainActor
struct FormInputBindingTests {
    @Test
    func inputBindingsReadCurrentStateAndWriteThroughItsUpdateAPI() {
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .requiredText, initialValue: .text("Initial")),
            FormField(id: .toggle, initialValue: .toggle(false))
        ])
        let binding = Binding(get: { state }, set: { state = $0 })
        let text = binding.formValue(for: .requiredText).formText
        let toggle = binding.formValue(for: .toggle).formToggle
        #expect(text.wrappedValue == "Initial")
        #expect(!toggle.wrappedValue)
        text.wrappedValue = "Edited"
        toggle.wrappedValue = true
        #expect(state.value(for: .requiredText) == .text("Edited"))
        #expect(state.value(for: .toggle) == .toggle(true))
        state.reset()
        #expect(text.wrappedValue == "Initial")
        #expect(!toggle.wrappedValue)
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
        let binding = Binding(get: { state }, set: { state = $0 })
        binding.formValue(for: .disabledText).formText.wrappedValue = "Ignored"
        binding.formValue(for: .childText).formText.wrappedValue = "Hidden"
        binding.formValue(for: .parentToggle).formText.wrappedValue = "Wrong kind"
        binding.formValue(for: .parentToggle).wrappedValue = nil
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
        let binding = Binding(get: { state }, set: { state = $0 })
        binding.selectFormOptions(["02", "01"], for: .firstChoice)
        binding.selectFormOptions(["02", "unknown", "01", "02"], for: .secondChoice)
        binding.selectFormOptions(["01"], for: .requiredText)
        #expect(state.value(for: .firstChoice) == .singleSelection("02"))
        #expect(state.value(for: .secondChoice) == .multipleSelection(["01", "02"]))
        #expect(state.value(for: .requiredText) == .text("Text"))
        binding.selectFormOptions([], for: .firstChoice)
        binding.selectFormOptions([], for: .secondChoice)
        #expect(state.value(for: .firstChoice) == .singleSelection(nil))
        #expect(state.value(for: .secondChoice) == .multipleSelection([]))
    }
}
