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
    static let scrollToLatest = "chat.scrollToLatest"
    static let question = "chat.question"
    static let failedQuestion = "chat.question.failed"
    static let dateChip = "chat.date"
    static let answer = "chat.answer"
    static let agentMessage = "chat.agent.message"
    static let agentTyping = "chat.agent.typing"
    static let liveAgentNotice = "chat.agent.notice"
    /// Chip awal/akhir sesi agen.
    static let liveAgentChip = "chat.agent.chip"
    static let leaveAgentQueue = "chat.agent.leaveQueue"

    /// Saran pertanyaan lanjutan ke-`index` (mulai 0) sesuai urutan dari gateway.
    static func followUp(_ index: Int) -> String { "chat.followUp.\(index)" }

    /// Kartu shortcut ke-`index` (mulai 0) sesuai urutan dari BE.
    static func shortcut(_ index: Int) -> String { "welcome.shortcut.\(index)" }
    /// Pesan foto galeri berformat lain di sheet lampiran.
    static let attachmentFormatError = "chat.attachment.formatError"

    static let referenceLetterForm = "chat.referenceLetter.form"
    static let referenceLetterSuccess = "chat.referenceLetter.success"
}
