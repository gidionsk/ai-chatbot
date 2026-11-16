//
//  TransactionPINRules.swift
//  DesignKit
//
//  Created by Wendra on 16/11/26.
//

/// Kontrak teknis PIN enam angka ASCII. Bukan nilai desain; metadata keypad tidak masuk copy bisnis.
public enum TransactionPINRules {
    public static let length = 6

    public static func isValid(_ value: String) -> Bool {
        value.utf8.count == length && value.utf8.allSatisfy { (48...57).contains($0) }
    }

}
