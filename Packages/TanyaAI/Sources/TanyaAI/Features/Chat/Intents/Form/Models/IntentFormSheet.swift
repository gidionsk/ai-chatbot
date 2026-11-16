//
//  IntentFormSheet.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// ID instance milik pesan gateway. Sheet dipasang sekali di root ChatScreen.
enum IntentFormSheet: Hashable {
    case referenceOptions(String, ReferenceLetterFieldID)

    var instanceID: String {
        switch self {
        case .referenceOptions(let id, _): return id
        }
    }
}
