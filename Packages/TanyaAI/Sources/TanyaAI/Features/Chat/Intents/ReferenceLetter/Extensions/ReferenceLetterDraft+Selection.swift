//
//  ReferenceLetterDraft+Selection.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import Foundation

public extension ReferenceLetterDraft {
    func selectedCodes(for field: ReferenceLetterFieldID) -> [String] {
        switch field {
        case .purpose: return purposeCode.map { [$0] } ?? []
        case .documentFormat: return documentFormatCode.map { [$0] } ?? []
        case .accounts: return accountCodes
        case .currency: return currencyCode.map { [$0] } ?? []
        case .language: return languageCode.map { [$0] } ?? []
        case .destination: return []
        }
    }

    /// ID tak dikenal dibuang; hasil mengikuti urutan BE dan tidak mengandung duplikat.
    mutating func select(_ codes: [String], for field: ReferenceLetterFieldID, inquiry: ReferenceLetterInquiry) {
        let requested = Set(codes)
        var seen: Set<String> = []
        let valid = field.options(in: inquiry).map(\.id).filter { requested.contains($0) && seen.insert($0).inserted }
        switch field {
        case .purpose: purposeCode = valid.first
        case .documentFormat: documentFormatCode = valid.first
        case .accounts: accountCodes = valid
        case .currency: currencyCode = valid.first
        case .language: languageCode = valid.first
        case .destination: break
        }
    }

    /// Validasi dijalankan caller ketika Kirim; field email/alamat read-only tidak divalidasi sebagai input.
    func invalidFields(in inquiry: ReferenceLetterInquiry) -> Set<ReferenceLetterFieldID> {
        var invalid: Set<ReferenceLetterFieldID> = []
        for field in [ReferenceLetterFieldID.purpose, .documentFormat, .accounts, .currency, .language] {
            let available = Set(field.options(in: inquiry).map(\.id))
            let selected = selectedCodes(for: field)
            if selected.isEmpty || !selected.allSatisfy(available.contains) { invalid.insert(field) }
        }
        if destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { invalid.insert(.destination) }
        if ReferenceLetterDocumentFormat(rawValue: documentFormatCode ?? String()) == nil {
            invalid.insert(.documentFormat)
        }
        if let languageCode, !inquiry.languages.contains(where: { $0.id == languageCode }) {
            invalid.insert(.language)
        }
        return invalid
    }
}
