//
//  TransactionPINRulesTests.swift
//  DesignKit
//
//  Created by Wendra on 16/11/26.
//

import Testing

@testable import DesignKit

struct TransactionPINRulesTests {
    @Test(arguments: ["123456", "000000", "987654"])
    func acceptsSixASCIIDigits(pin: String) {
        #expect(TransactionPINRules.isValid(pin))
    }

    @Test(arguments: ["", "12345", "1234567", "１２３４５６", "123a56", "123 56"])
    func rejectsMalformedInput(pin: String) {
        #expect(!TransactionPINRules.isValid(pin))
    }
}
