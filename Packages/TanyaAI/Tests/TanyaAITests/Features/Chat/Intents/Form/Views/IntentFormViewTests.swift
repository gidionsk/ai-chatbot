//
//  IntentFormViewTests.swift
//  TanyaAITests
//
//  Created by Wendra on 18/11/26.
//

import DesignKit
import SwiftUI
import Testing
import UIKit

@testable import TanyaAI

@MainActor
struct IntentFormViewTests {
    @Test
    func confirmationErrorsAddSpaceBelowTheExistingInputs() throws {
        try FontFace.registerFonts()
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .requiredText, initialValue: .text(String()), isRequired: true),
            FormField(id: .firstChoice, initialValue: .singleSelection(nil), isRequired: true)
        ])
        let plain = size(of: form(state))
        let isValid = state.validate()
        #expect(!isValid)
        let invalid = size(of: form(state))
        #expect(invalid.height > plain.height + FigmaSize.spacingLarge.scaledToArtwork)
    }

    @Test
    func aHiddenDependentFieldTakesNoSpaceUntilItsParentMatches() throws {
        try FontFace.registerFonts()
        var state = IntentFormState<TestFormFieldID>(fields: [
            FormField(id: .parentToggle, initialValue: .toggle(false)),
            FormField(
                id: .childText,
                initialValue: .text("Stored email"),
                isEnabled: false,
                condition: FormFieldCondition(fieldID: .parentToggle, value: .toggle(true))
            )
        ])
        let hidden = size(of: form(state))
        state.update(.toggle(true), for: .parentToggle)
        let visible = size(of: form(state))
        #expect(visible.height > hidden.height + FigmaSize.spacingLarge.scaledToArtwork)
    }

    @Test
    func aMissingFieldRendersNoInput() {
        let field = IntentFormField(
            value: .constant(nil),
            presentation: presentation,
            selectionText: nil,
            error: nil,
            onOpenChoices: {}
        )
        #expect(size(of: field).height == .zero)
    }

    @Test
    func optionSubtitlesFromTheHostAreShownInTheSheetContent() throws {
        try FontFace.registerFonts()
        let plain = options(subtitle: nil)
        let detailed = options(subtitle: "Available balance")
        #expect(size(of: detailed).height > size(of: plain).height)
    }
}

// MARK: - Helpers

private extension IntentFormViewTests {
    var presentation: FormFieldPresentation {
        FormFieldPresentation(label: "Field", placeholder: "Choose or enter", requiredError: "Required")
    }

    func form(_ state: IntentFormState<TestFormFieldID>) -> some View {
        IntentFormView(
            state: .constant(state),
            title: "Form",
            confirmLabel: "Confirm",
            cancelLabel: "Cancel",
            presentation: { _ in presentation },
            selectionSummary: { _, options in options.map(\.title).joined(separator: ", ") },
            onOpenChoices: { _ in },
            onConfirm: {},
            onCancel: {}
        )
    }

    func options(subtitle: String?) -> some View {
        let state = IntentFormState<TestFormFieldID>(fields: [
            FormField(
                id: .firstChoice,
                initialValue: .singleSelection(nil),
                options: [FormOption(code: "01", title: "Account", subtitle: subtitle)]
            )
        ])
        return IntentFormOptions(
            state: .constant(state),
            fieldID: .firstChoice,
            title: "Choose account",
            confirmLabel: "Select",
            onSelect: {}
        )
    }

    func size(of content: some View) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: 375, height: 2_000))
    }
}
