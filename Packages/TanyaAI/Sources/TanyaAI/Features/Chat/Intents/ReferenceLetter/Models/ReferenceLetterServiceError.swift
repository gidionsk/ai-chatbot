//
//  ReferenceLetterServiceError.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

/// Pesan dipilih host sesuai locale, tanpa PIN atau token.
public enum ReferenceLetterServiceError: Error {
    case authorization(String)
    /// Penolakan eksplisit BE; berbeda dari timeout yang status transaksinya belum pasti.
    case rejected(String)
}
