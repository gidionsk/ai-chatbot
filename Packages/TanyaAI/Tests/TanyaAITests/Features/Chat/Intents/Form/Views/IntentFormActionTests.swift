//
//  IntentFormActionTests.swift
//  TanyaAITests
//
//  Created by Wendra on 18/11/26.
//

import SwiftUI
import Testing

@testable import TanyaAI

@MainActor
struct IntentFormActionTests {
    @Test
    func confirmationStoresAllErrorsBeforeOpeningTheFirstInvalidChoice() {
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .requiredText, initialValue: .text(String()), isRequired: true),
            FormField(id: .secondChoice, initialValue: .multipleSelection([]), isRequired: true),
            FormField(id: .firstChoice, initialValue: .singleSelection(nil), isRequired: true)
        ])
        let binding = Binding(get: { state }, set: { state = $0 })
        var opened: [TestFormFieldID] = []
        var isConfirmed = false
        let content = makeForm(
            binding,
            onOpenChoices: { fieldID in
                #expect(state.invalidFieldIDs == [.requiredText, .secondChoice, .firstChoice])
                opened.append(fieldID)
            },
            onConfirm: { isConfirmed = true }
        )
        content.confirm()
        #expect(opened == [.secondChoice])
        #expect(!isConfirmed)
    }

    @Test
    func aTextErrorDoesNotOpenAnUnrelatedChoiceOrConfirm() {
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .requiredText, initialValue: .text("   "), isRequired: true),
            FormField(id: .firstChoice, initialValue: .singleSelection(nil))
        ])
        let binding = Binding(get: { state }, set: { state = $0 })
        var opened: [TestFormFieldID] = []
        var isConfirmed = false
        let content = makeForm(
            binding,
            onOpenChoices: { opened.append($0) },
            onConfirm: { isConfirmed = true }
        )
        content.confirm()
        #expect(state.invalidFieldIDs == [.requiredText])
        #expect(opened.isEmpty)
        #expect(!isConfirmed)
    }

    @Test
    func aValidConfirmationCallsTheOwnerOnceAfterClearingErrors() {
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .requiredText, initialValue: .text(String()), isRequired: true)
        ])
        let binding = Binding(get: { state }, set: { state = $0 })
        let isInitiallyValid = state.validate()
        #expect(!isInitiallyValid)
        state[text: .requiredText] = "Complete"
        var confirmed = 0
        let content = makeForm(
            binding,
            onOpenChoices: { _ in Issue.record("A complete form must not open a choice") },
            onConfirm: {
                #expect(state.invalidFieldIDs.isEmpty)
                #expect(state.value(for: .requiredText) == .text("Complete"))
                confirmed += 1
            }
        )
        content.confirm()
        #expect(confirmed == 1)
    }

    @Test
    func cancellationRestoresDefaultsAndClearsErrorsBeforeNotifyingTheOwner() {
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .requiredText, initialValue: .text(String()), isRequired: true),
            FormField(id: .toggle, initialValue: .toggle(false))
        ])
        let binding = Binding(get: { state }, set: { state = $0 })
        state[toggle: .toggle] = true
        let isValid = state.validate()
        #expect(!isValid)
        var isCancelled = false
        let content = makeForm(binding, onOpenChoices: { _ in }, onConfirm: {}) {
            #expect(state.value(for: .toggle) == .toggle(false))
            #expect(state.invalidFieldIDs.isEmpty)
            isCancelled = true
        }
        content.cancel()
        #expect(isCancelled)
    }
}

// MARK: - Helpers

private extension IntentFormActionTests {
    func makeForm(
        _ state: Binding<IntentFormState<TestFormFieldID>>,
        onOpenChoices: @escaping (TestFormFieldID) -> Void,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) -> IntentFormView<TestFormFieldID> {
        IntentFormView(
            state: state,
            title: "Form",
            confirmLabel: "Confirm",
            cancelLabel: "Cancel",
            presentation: { _ in FormFieldPresentation(label: "Field", requiredError: "Required") },
            selectionSummary: { _, options in options.map(\.title).joined(separator: ", ") },
            onOpenChoices: onOpenChoices,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}
