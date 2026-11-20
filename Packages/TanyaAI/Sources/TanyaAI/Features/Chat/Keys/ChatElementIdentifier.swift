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
    static let answerLoading = "chat.answer.loading"
    static let liveAgentNotice = "chat.agent.notice"
    /// Tombol batal di dalam kartu antre.
    static let leaveAgentQueue = "chat.agent.leaveQueue"
    /// Bar sesi agen di bawah header; End Session di dalamnya dicari lewat label.
    static let agentSessionBanner = "chat.agent.session"

    /// Saran pertanyaan lanjutan ke-`index` (mulai 0) sesuai urutan dari gateway.
    static func followUp(_ index: Int) -> String { "chat.followUp.\(index)" }

    /// Kartu shortcut ke-`index` (mulai 0) sesuai urutan dari BE.
    static func shortcut(_ index: Int) -> String { "welcome.shortcut.\(index)" }
    /// Pesan foto galeri berformat lain di sheet lampiran.
    static let attachmentFormatError = "chat.attachment.formatError"
}
