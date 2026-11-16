//
//  PinPadKeyTests.swift
//  DesignKitTests
//
//  Created by Wendra on 16/11/26.
//

import Testing

@testable import DesignKit

/// Keypad PIN: angka ditambah sampai panjang PIN, hapus membuang digit terakhir, dan susunannya seperti keypad
/// telepon.
struct PinPadKeyTests {
    private let length = 6

    @Test
    func digitsAreAddedUntilThePinIsFull() {
        var pin = String()
        for digit in [1, 2, 3, 4, 5, 6, 7] {
            pin = PinPadKey.digit(digit).applied(to: pin, length: length)
        }
        #expect(pin == "123456")
    }

    @Test
    func deleteRemovesTheLastDigitAndIgnoresAnEmptyPin() {
        #expect(PinPadKey.delete.applied(to: "123", length: length) == "12")
        #expect(PinPadKey.delete.applied(to: String(), length: length).isEmpty)
    }

    @Test
    func theKeypadIsLaidOutLikeAPhoneKeypad() {
        let digits = PinPadKey.rows.prefix(3).flatMap { $0 }
        #expect(digits == (1...9).map { PinPadKey.digit($0) })
        #expect(PinPadKey.rows.last == [nil, .digit(0), .delete])
    }
}
