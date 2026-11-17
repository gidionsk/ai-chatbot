//
//  IntentFormDependencyTests.swift
//  TanyaAITests
//
//  Created by Wendra on 17/11/26.
//

import Testing

@testable import TanyaAI

struct IntentFormDependencyTests {
    @Test
    func hiddenInputIsRemovedAndReturnsToItsInitialValueWhenShownAgain() {
        var state = dependentState()
        #expect(state.value(for: .childText) == nil)
        let isValid = state.validate()
        #expect(isValid)
        state.update(.toggle(true), for: .parentToggle)
        #expect(state.value(for: .childText) == .text(String()))
        let isValidAfterEdit = state.validate()
        #expect(!isValidAfterEdit)
        state.update(.text("Entered"), for: .childText)
        #expect(state.invalidFieldIDs.isEmpty)
        state.update(.toggle(false), for: .parentToggle)
        #expect(state.value(for: .childText) == nil)
        let isValidAfterHiding = state.validate()
        #expect(isValidAfterHiding)
        state.update(.text("Ignored hidden input"), for: .childText)
        state.update(.toggle(true), for: .parentToggle)
        #expect(state.value(for: .childText) == .text(String()))
    }

    @Test
    func dependencyChainsWorkWhenChildrenPrecedeTheirParents() {
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(
                id: .grandchildText,
                initialValue: .text(String()),
                isRequired: true,
                condition: FormFieldCondition(fieldID: .childText, value: .text("Show"))
            ),
            FormField(
                id: .childText,
                initialValue: .text("Show"),
                condition: FormFieldCondition(fieldID: .parentToggle, value: .toggle(true))
            ),
            FormField(id: .parentToggle, initialValue: .toggle(false))
        ])
        state.update(.toggle(true), for: .parentToggle)
        #expect(state.visibleFields.map(\.id) == [.grandchildText, .childText, .parentToggle])
        let isValid = state.validate()
        #expect(!isValid)
        state.update(.text("Entered"), for: .grandchildText)
        state.update(.toggle(false), for: .parentToggle)
        #expect(state.value(for: .grandchildText) == nil)
        #expect(state.invalidFieldIDs.isEmpty)
        state.update(.toggle(true), for: .parentToggle)
        #expect(state.value(for: .grandchildText) == .text(String()))
    }

    @Test
    func missingParentsAndCyclesStayHiddenWithoutBlockingConfirmation() {
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(
                id: .childText,
                initialValue: .text(String()),
                isRequired: true,
                condition: FormFieldCondition(fieldID: .grandchildText, value: .text(String()))
            ),
            FormField(
                id: .grandchildText,
                initialValue: .text(String()),
                isRequired: true,
                condition: FormFieldCondition(fieldID: .childText, value: .text(String()))
            ),
            FormField(
                id: .requiredText,
                initialValue: .text(String()),
                isRequired: true,
                condition: FormFieldCondition(fieldID: .parentToggle, value: .toggle(true))
            )
        ])
        #expect(state.visibleFields.isEmpty)
        let isValid = state.validate()
        #expect(isValid)
    }

    @Test
    func resetRestoresTheInitialDraftAndClearsErrors() {
        var state = dependentState()
        state.update(.toggle(true), for: .parentToggle)
        let isValid = state.validate()
        #expect(!isValid)
        state.reset()
        #expect(state.value(for: .parentToggle) == .toggle(false))
        #expect(state.value(for: .childText) == nil)
        #expect(state.invalidFieldIDs.isEmpty)
        #expect(state.firstInvalidChoiceID == nil)
    }
}

// MARK: - Helpers

private extension IntentFormDependencyTests {
    func dependentState() -> IntentFormState<TestFormFieldID> {
        IntentFormState(fields: [
            FormField(id: .parentToggle, initialValue: .toggle(false)),
            FormField(
                id: .childText,
                initialValue: .text(String()),
                isRequired: true,
                condition: FormFieldCondition(fieldID: .parentToggle, value: .toggle(true))
            )
        ])
    }
}
