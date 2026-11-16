//
//  Array+IntentForms.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

extension Array where Element == ChatListItem {
    func insertingReferenceLetters(_ ids: Set<String>) -> Self {
        flatMap { item in
            guard case .message(let row, _) = item, ids.contains(row.id) else { return [item] }
            return [item, .referenceLetter(row.id)]
        }
    }
}
