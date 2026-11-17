//
//  FormOptionTests.swift
//  TanyaAITests
//
//  Created by Wendra on 17/11/26.
//

import Testing

@testable import TanyaAI

struct FormOptionTests {
    @Test
    func aChoiceWithoutSupportingTextHasNoSubtitle() {
        let option = FormOption(code: "choice-a", title: "Sample purpose")
        #expect(option.subtitle == nil)
    }
}
