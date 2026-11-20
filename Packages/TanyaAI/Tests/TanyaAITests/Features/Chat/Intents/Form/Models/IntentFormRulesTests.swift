//
//  IntentFormRulesTests.swift
//  TanyaAITests
//
//  Created by Wendra on 19/11/26.
//

import Testing

@testable import TanyaAI

struct IntentFormRulesTests {
    @Test
    func changingTheParentReplacesOptionsAndDiscardsAnUnavailableSelection() {
        var state = IntentFormState(rules: MockProductFormRules.rules)
        state.select(["equity"], for: .product)
        state.select(["checking"], for: .fundingAccount)
        state[text: .details] = "Keep unrelated input"
        state.select(["deposit"], for: .category)
        let options = state.visibleFields.first { $0.id == .product }?.options
        #expect(options?.map(\.code) == ["shared", "fixed"])
        #expect(state.value(for: .product) == .singleSelection(nil))
        #expect(state.value(for: .fundingAccount) == .multipleSelection(["checking"]))
        #expect(state.value(for: .details) == .text("Keep unrelated input"))
    }

    @Test
    func changingTheParentResetsASelectionEvenIfItIsStillAvailable() {
        var state = IntentFormState(rules: MockProductFormRules.rules)
        state.select(["shared"], for: .product)
        state.select(["deposit"], for: .category)
        #expect(state.value(for: .product) == .singleSelection(nil))
    }

    @Test
    func textIsRequiredOnlyWhileTheToggleIsOnAndErrorsStillWaitForConfirmation() {
        var state = completeProductState()
        let isInitiallyValid = state.validate()
        #expect(isInitiallyValid)
        state[toggle: .needsDetails] = true
        #expect(state.invalidFieldIDs.isEmpty)
        let isValidWithRequiredText = state.validate()
        #expect(!isValidWithRequiredText)
        #expect(state.invalidFieldIDs == [.details])
        state[text: .details] = "Entered"
        #expect(state.invalidFieldIDs.isEmpty)
        state[text: .details] = String()
        let isValidAfterClearing = state.validate()
        #expect(!isValidAfterClearing)
        state[toggle: .needsDetails] = false
        #expect(state.invalidFieldIDs.isEmpty)
        let isValidWhenOptional = state.validate()
        #expect(isValidWhenOptional)
    }

    @Test
    func theFirstEmptyChoiceFollowsTheLatestRuleOrder() {
        var state = IntentFormState(rules: MockProductFormRules.rules)
        let isInitiallyValid = state.validate()
        #expect(!isInitiallyValid)
        #expect(state.firstInvalidChoiceID == .product)
        state.select(["deposit"], for: .category)
        let isValidAfterReordering = state.validate()
        #expect(!isValidAfterReordering)
        #expect(state.visibleFields.map(\.id) == [.category, .fundingAccount, .product, .needsDetails, .details])
        #expect(state.firstInvalidChoiceID == .fundingAccount)
    }

    @Test
    func cancellationDefaultsAreRebuiltFromTheProductRules() {
        var state = completeProductState()
        state.select(["deposit"], for: .category)
        state[toggle: .needsDetails] = true
        let isValid = state.validate()
        #expect(!isValid)
        state.reset()
        let initial = IntentFormState(rules: MockProductFormRules.rules)
        #expect(state.values == initial.values)
        #expect(state.visibleFields.map(\.id) == initial.visibleFields.map(\.id))
        #expect(state.invalidFieldIDs.isEmpty)
    }
}

// MARK: - Helpers

private extension IntentFormRulesTests {
    func completeProductState() -> IntentFormState<MockProductFieldID> {
        var state = IntentFormState(rules: MockProductFormRules.rules)
        state.select(["shared"], for: .product)
        state.select(["checking"], for: .fundingAccount)
        return state
    }
}
