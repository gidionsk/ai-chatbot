//
//  IntentFormSheet.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// ID instance milik pesan gateway. Sheet dipasang sekali di root ChatScreen.
enum IntentFormSheet: Hashable {
    case referenceOptions(String, ReferenceLetterFieldID)
    case referencePIN(String)

    var instanceID: String {
        switch self {
        case .referenceOptions(let id, _), .referencePIN(let id): return id
        }
    }
}
