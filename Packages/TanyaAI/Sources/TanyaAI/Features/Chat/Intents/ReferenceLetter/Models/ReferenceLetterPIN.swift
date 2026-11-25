//
//  ReferenceLetterPIN.swift
//  TanyaAI
//
//  Created by Wendra on 22/11/26.
//

/// Panjang PIN transaksi untuk Surat Referensi.
enum ReferenceLetterPIN {
    static let length = 6

    static func isValid(_ pin: String) -> Bool {
        pin.utf8.count == length && pin.utf8.allSatisfy { (UInt8(ascii: "0")...UInt8(ascii: "9")).contains($0) }
    }
}
