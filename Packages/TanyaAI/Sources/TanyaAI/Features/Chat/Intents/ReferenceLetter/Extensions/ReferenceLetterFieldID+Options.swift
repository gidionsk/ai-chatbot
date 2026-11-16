//
//  ReferenceLetterFieldID+Options.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import DesignKit

public extension ReferenceLetterFieldID {
    func options(in inquiry: ReferenceLetterInquiry) -> [OptionItem] {
        switch self {
        case .purpose: return inquiry.purposes
        case .documentFormat: return inquiry.documentFormats
        case .accounts: return inquiry.sourceAccounts
        case .currency: return inquiry.currencies
        case .language: return inquiry.languages
        case .destination: return []
        }
    }

    var isMultiple: Bool { self == .accounts }
}
