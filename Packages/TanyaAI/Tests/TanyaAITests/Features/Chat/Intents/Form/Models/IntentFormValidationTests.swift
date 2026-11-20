//
//  IntentFormValidationTests.swift
//  TanyaAITests
//
//  Created by Wendra on 17/11/26.
//

import Testing

@testable import TanyaAI

struct IntentFormValidationTests {
    @Test
    func errorsOnlyAppearOnConfirmationAndTheFirstEmptyChoiceUsesDefinitionOrder() {
        var state = IntentFormState<TestFormFieldID>(
            rules: .fixed([
                FormField(id: .requiredText, initialValue: .text(String()), isRequired: true),
                FormField(id: .secondChoice, initialValue: .multipleSelection([]), isRequired: true),
                FormField(id: .firstChoice, initialValue: .singleSelection(nil), isRequired: true)
            ]))
        #expect(state.invalidFieldIDs.isEmpty)
        #expect(state.firstInvalidChoiceID == nil)
        let isValid = state.validate()
        #expect(!isValid)
        #expect(state.invalidFieldIDs == [.requiredText, .secondChoice, .firstChoice])
        #expect(state.firstInvalidChoiceID == .secondChoice)
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func requiredTextRejectsBlankInputOnConfirmation(text: String) {
        var state = IntentFormState<TestFormFieldID>(
            rules: .fixed([
                FormField(id: .requiredText, initialValue: .text(text), isRequired: true)
            ]))
        let isValid = state.validate()
        #expect(!isValid)
        state.update(.text("Entered value"), for: .requiredText)
        #expect(state.invalidFieldIDs.isEmpty)
        let isValidAfterEdit = state.validate()
        #expect(isValidAfterEdit)
    }

    @Test
    func editingDoesNotMarkANewlyEmptyFieldUntilTheNextConfirmation() {
        var state = IntentFormState<TestFormFieldID>(
            rules: .fixed([
                FormField(id: .requiredText, initialValue: .text("Initial"), isRequired: true)
            ]))
        let isValid = state.validate()
        #expect(isValid)
        state.update(.text(String()), for: .requiredText)
        #expect(state.invalidFieldIDs.isEmpty)
        let isValidAfterEdit = state.validate()
        #expect(!isValidAfterEdit)
        #expect(state.invalidFieldIDs == [.requiredText])
    }

    @Test
    func disabledAndOptionalFieldsDoNotBlockConfirmation() {
        var state = IntentFormState<TestFormFieldID>(
            rules: .fixed([
                FormField(id: .disabledText, initialValue: .text(String()), isRequired: true, isEnabled: false),
                FormField(id: .requiredText, initialValue: .text(String())),
                FormField(id: .toggle, initialValue: .toggle(false), isRequired: true)
            ]))
        state.update(.text("Ignored"), for: .disabledText)
        #expect(state.value(for: .disabledText) == .text(String()))
        let isValid = state.validate()
        #expect(isValid)
    }

    @Test
    func emptyOrUnavailableChoiceListsCannotSatisfyARequiredSelection() {
        var state = IntentFormState<TestFormFieldID>(
            rules: .fixed([
                FormField(id: .firstChoice, initialValue: .singleSelection("stale"), isRequired: true),
                FormField(id: .secondChoice, initialValue: .multipleSelection(["stale"]), isRequired: true)
            ]))
        let isValid = state.validate()
        #expect(!isValid)
        #expect(state.invalidFieldIDs == [.firstChoice, .secondChoice])
    }

    @Test
    func anEmptyFormDoesNotCreateErrors() {
        var state = IntentFormState<TestFormFieldID>(rules: .fixed([]))
        let isValid = state.validate()
        #expect(isValid)
        #expect(state.firstInvalidChoiceID == nil)
    }
}
