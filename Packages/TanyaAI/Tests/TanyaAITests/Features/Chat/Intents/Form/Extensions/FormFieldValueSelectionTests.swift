//
//  FormFieldValueSelectionTests.swift
//  TanyaAITests
//
//  Created by Wendra on 18/11/26.
//

import Testing

@testable import TanyaAI

struct FormFieldValueSelectionTests {
    @Test(arguments: [
        FormFieldValue.singleSelection(nil),
        .text("Not a choice"),
        .toggle(true)
    ])
    func nonSelectionsHaveNoCodes(value: FormFieldValue) {
        #expect(value.selectedCodes.isEmpty)
    }

    @Test
    func selectionsKeepOpaqueCodesAndTheirOrder() {
        #expect(FormFieldValue.singleSelection("02").selectedCodes == ["02"])
        #expect(FormFieldValue.multipleSelection(["02", "01"]).selectedCodes == ["02", "01"])
    }
}
