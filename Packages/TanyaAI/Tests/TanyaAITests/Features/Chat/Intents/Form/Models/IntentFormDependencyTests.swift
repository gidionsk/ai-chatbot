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
    func changingTheParentUsesTheNewChildDefaultEvenIfTheOldChoiceRemainsAvailable() {
        let choices = [FormOption(code: "old", title: "Old"), FormOption(code: "new", title: "New")]
        let rules = IntentFormRules<TestFormFieldID>(
            fields: { values in
                [
                    FormField(id: .parentToggle, initialValue: .toggle(false)),
                    FormField(
                        id: .firstChoice,
                        initialValue: .singleSelection(values[.parentToggle] == .toggle(true) ? "new" : "old"),
                        options: choices
                    )
                ]
            },
            fieldsToReset: { $0 == .parentToggle ? [.firstChoice] : [] }
        )
        var state = IntentFormState(rules: rules)
        #expect(state.value(for: .firstChoice) == .singleSelection("old"))
        state[toggle: .parentToggle] = true
        #expect(state.value(for: .firstChoice) == .singleSelection("new"))
    }

    @Test(arguments: [false, true])
    func changingTheParentResetsAllDescendants(isCyclic: Bool) {
        let rules = IntentFormRules<TestFormFieldID>(
            fields: { values in
                [
                    FormField(id: .parentToggle, initialValue: .toggle(false)),
                    FormField(id: .childText, initialValue: .text("Child")),
                    FormField(
                        id: .grandchildText,
                        initialValue: .text(values[.childText] == .text("Child") ? "Grandchild" : "Pending")
                    )
                ]
            },
            fieldsToReset: { fieldID in
                switch fieldID {
                case .parentToggle:
                    return [.childText]
                case .childText:
                    return [.grandchildText]
                case .grandchildText:
                    return isCyclic ? [.parentToggle] : []
                default:
                    return []
                }
            }
        )
        var state = IntentFormState(rules: rules)
        state[text: .childText] = "Edited child"
        state[text: .grandchildText] = "Edited grandchild"
        state[toggle: .parentToggle] = true
        #expect(state.value(for: .parentToggle) == .toggle(true))
        #expect(state.value(for: .childText) == .text("Child"))
        #expect(state.value(for: .grandchildText) == .text("Grandchild"))
    }

    @Test
    func aParentDefaultRevealsItsChildOnInitAndReset() {
        let rules = IntentFormRules<TestFormFieldID>(
            fields: { values in
                let parent = FormField<TestFormFieldID>(id: .parentToggle, initialValue: .toggle(true))
                guard values[.parentToggle] == .toggle(true) else { return [parent] }
                return [parent, FormField(id: .childText, initialValue: .text("Shown by default"))]
            },
            fieldsToReset: { $0 == .parentToggle ? [.childText] : [] }
        )
        var state = IntentFormState(rules: rules)
        #expect(state.visibleFields.map(\.id) == [.parentToggle, .childText])
        #expect(state.value(for: .childText) == .text("Shown by default"))
        state[toggle: .parentToggle] = false
        #expect(state.value(for: .childText) == nil)
        state.reset()
        #expect(state.visibleFields.map(\.id) == [.parentToggle, .childText])
        #expect(state.value(for: .childText) == .text("Shown by default"))
    }

    @Test
    func fieldReconciliationReachesTheStableFormOnInitAndReset() {
        let rules = IntentFormRules<TestFormFieldID>(
            fields: { values in
                let format = FormField<TestFormFieldID>(id: .parentToggle, initialValue: .toggle(true))
                let address = FormField<TestFormFieldID>(
                    id: .childText, initialValue: .text(String()), isRequired: true)
                let email = FormField<TestFormFieldID>(
                    id: .grandchildText, initialValue: .text(String()), isRequired: true)
                let extra = FormField<TestFormFieldID>(
                    id: .requiredText, initialValue: .text(String()), isRequired: true)
                if values[extra.id] != nil { return [format] }
                if values[email.id] != nil { return [email, extra] }
                if values[address.id] != nil { return [address, email] }
                if values[format.id] != nil { return [format] }
                return [format, address]
            },
            fieldsToReset: { _ in [] }
        )
        var state = IntentFormState(rules: rules)
        #expect(state.visibleFields.map(\.id) == [.parentToggle])
        #expect(state.values == [.parentToggle: .toggle(true)])
        let isValid = state.validate()
        #expect(isValid)

        state[toggle: .parentToggle] = false
        state.reset()
        #expect(state.visibleFields.map(\.id) == [.parentToggle])
        #expect(state.values == [.parentToggle: .toggle(true)])
        let isValidAfterReset = state.validate()
        #expect(isValidAfterReset)
    }

    @Test
    func fieldReconciliationStopsWhenRulesKeepAlternating() {
        let rules = IntentFormRules<TestFormFieldID>(
            fields: { values in
                let parent = FormField<TestFormFieldID>(id: .parentToggle, initialValue: .toggle(true))
                guard values[.childText] == nil else { return [parent] }
                return [parent, FormField(id: .childText, initialValue: .text("Alternating"))]
            },
            fieldsToReset: { _ in [] }
        )
        let state = IntentFormState(rules: rules)
        #expect(Set(state.values.keys) == Set(state.visibleFields.map(\.id)))
    }

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
