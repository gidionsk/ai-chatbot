//
//  ChatElementIdentifier.swift
//  TanyaAI
//
//  Created by Wendra on 17/10/26.
//

/// Technical identifiers are separate from localized user-facing strings.
enum ChatElementIdentifier {
    static let welcome = "chat.welcome"
    static let loading = "chat.loading"
    static let messages = "chat.messages"
    static let question = "chat.question"
    static let failedQuestion = "chat.question.failed"
    static let dateChip = "chat.date"

    /// Kartu shortcut ke-`index` (mulai 0) sesuai urutan dari BE.
    static func shortcut(_ index: Int) -> String { "welcome.shortcut.\(index)" }
}
