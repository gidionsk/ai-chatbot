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
    func aChoiceWithoutSupportingTextKeepsItsHostCodeAndTitle() {
        let option = FormOption(code: "choice-a", title: "Sample purpose")
        #expect(option.code == "choice-a")
        #expect(option.title == "Sample purpose")
        #expect(option.subtitle == nil)
    }

    @Test
    func anAccountChoicePreservesItsNameNumberAndBalance() {
        let option = FormOption(code: "account-a", title: "Sample account - 1234", subtitle: "Sample balance")
        #expect(option.title == "Sample account - 1234")
        #expect(option.subtitle == "Sample balance")
    }
}
