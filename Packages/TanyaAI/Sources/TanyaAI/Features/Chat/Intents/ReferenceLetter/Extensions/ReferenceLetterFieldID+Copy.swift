//
//  ReferenceLetterFieldID+Copy.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

extension ReferenceLetterFieldID {
    var label: ChatCopy {
        switch self {
        case .purpose: return .referencePurpose
        case .documentFormat: return .referenceFormat
        case .destination: return .referenceDestination
        case .accounts: return .referenceAccounts
        case .currency: return .referenceCurrency
        case .language: return .referenceLanguage
        }
    }
}
