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

    static let columns = 3
    static let keys: [String?] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", nil, "0"]
    static let lockSymbol = "lock"
    static let dotSymbol = "circle.fill"
    static let deleteSymbol = "arrow.left"
}
