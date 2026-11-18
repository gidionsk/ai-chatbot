//
//  FormActionBindingTests.swift
//  TanyaAITests
//
//  Created by Wendra on 18/11/26.
//

import SwiftUI
import Testing

@testable import TanyaAI

@MainActor
struct FormActionBindingTests {
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
        binding.confirmForm(
            onInvalidChoice: { fieldID in
                #expect(state.invalidFieldIDs == [.requiredText, .secondChoice, .firstChoice])
                opened.append(fieldID)
            },
            onValid: { isConfirmed = true }
        )
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
        binding.confirmForm(onInvalidChoice: { opened.append($0) }, onValid: { isConfirmed = true })
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
        binding.formValue(for: .requiredText).formText.wrappedValue = "Complete"
        var confirmed = 0
        binding.confirmForm(
            onInvalidChoice: { _ in Issue.record("A complete form must not open a choice") },
            onValid: {
                #expect(state.invalidFieldIDs.isEmpty)
                #expect(state.value(for: .requiredText) == .text("Complete"))
                confirmed += 1
            }
        )
        #expect(confirmed == 1)
    }

    @Test
    func cancellationRestoresDefaultsAndClearsErrorsBeforeNotifyingTheOwner() {
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .requiredText, initialValue: .text(String()), isRequired: true),
            FormField(id: .toggle, initialValue: .toggle(false))
        ])
        let binding = Binding(get: { state }, set: { state = $0 })
        binding.formValue(for: .toggle).formToggle.wrappedValue = true
        let isValid = state.validate()
        #expect(!isValid)
        var isCancelled = false
        binding.resetForm {
            #expect(state.value(for: .toggle) == .toggle(false))
            #expect(state.invalidFieldIDs.isEmpty)
            isCancelled = true
        }
        #expect(isCancelled)
    }
}
