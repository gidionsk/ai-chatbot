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
    func aDifferentPurposeResetsEveryFollowingFieldBeforeRecomputingVisibility() {
        var state = editedLetterState()
        state.select(["other"], for: .purpose)
        #expect(state.value(for: .purpose) == .singleSelection("other"))
        #expect(state.value(for: .format) == .singleSelection("softcopy"))
        #expect(state.value(for: .embassy) == .text(String()))
        #expect(state.value(for: .accounts) == .multipleSelection([]))
        #expect(state.value(for: .currency) == .singleSelection("idr"))
        #expect(state.value(for: .balance) == .toggle(false))
        #expect(state.value(for: .address) == nil)
        #expect(state.value(for: .email) == .text("stored@example.test"))
    }

    @Test
    func selectingTheSamePurposePreservesTheWholeDraft() {
        var state = editedLetterState()
        let previous = state.values
        state.select(["visa"], for: .purpose)
        #expect(state.values == previous)
    }

    @Test
    func hiddenInputIsRemovedAndReturnsToItsInitialValueWhenShownAgain() {
        var state = IntentFormState(rules: MockLetterFormRules.rules)
        #expect(state.value(for: .address) == nil)
        state.select(["hardcopy"], for: .format)
        #expect(state.value(for: .email) == nil)
        state[text: .address] = "Edited address"
        state.select(["softcopy"], for: .format)
        #expect(state.value(for: .address) == nil)
        #expect(Set(state.values.keys) == Set(state.visibleFields.map(\.id)))
        state[text: .address] = "Ignored hidden input"
        state.select(["hardcopy"], for: .format)
        #expect(state.value(for: .address) == .text("Stored address"))
    }

    @Test
    func rulesCanPlaceDependentFieldsBeforeTheirControls() {
        let mock = MockLetterFormRules.rules
        let rules = IntentFormRules(
            fields: { Array(mock.fields($0).reversed()) },
            fieldsToReset: mock.fieldsToReset
        )
        var state = IntentFormState(rules: rules)
        #expect(state.visibleFields.first?.id == .email)
        state.select(["hardcopy"], for: .format)
        #expect(state.visibleFields.first?.id == .address)
        #expect(state.visibleFields.last?.id == .purpose)
        #expect(state.value(for: .email) == nil)
    }

    @Test
    func hidingAnInvalidFieldClearsItsErrorAndExcludesItFromValidation() {
        var state = editedLetterState()
        state[text: .address] = String()
        let isValid = state.validate()
        #expect(!isValid)
        #expect(state.invalidFieldIDs == [.address])
        state.select(["softcopy"], for: .format)
        #expect(state.invalidFieldIDs.isEmpty)
        let isValidAfterHiding = state.validate()
        #expect(isValidAfterHiding)
    }

    @Test
    func resetRestoresTheInitialDraftAndClearsErrors() {
        var state = editedLetterState()
        state[text: .embassy] = String()
        let isValid = state.validate()
        #expect(!isValid)
        state.reset()
        let initial = IntentFormState(rules: MockLetterFormRules.rules)
        #expect(state.values == initial.values)
        #expect(state.visibleFields.map(\.id) == initial.visibleFields.map(\.id))
        #expect(state.invalidFieldIDs.isEmpty)
        #expect(state.firstInvalidChoiceID == nil)
    }
}

// MARK: - Helpers

private extension IntentFormDependencyTests {
    func editedLetterState() -> IntentFormState<MockLetterFieldID> {
        var state = IntentFormState(rules: MockLetterFormRules.rules)
        state.select(["hardcopy"], for: .format)
        state[text: .address] = "Edited address"
        state[text: .embassy] = "Embassy"
        state.select(["other"], for: .accounts)
        state.select(["usd"], for: .currency)
        state[toggle: .balance] = true
        return state
    }
}
