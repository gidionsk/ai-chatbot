//
//  ChatCopy.swift
//  TanyaAI
//
//  Created by Wendra on 27/10/26.
//

/// Key copy Tanya AI di `Resources/*.lproj/Localizable.strings`. Satu-satunya tempat key ditulis;
/// `LocalizationTests` memastikan setiap case ada di en/id/zh-Hans dan tidak ada key yang yatim.
enum ChatCopy: String, CaseIterable {
    case placeholder = "chat.placeholder"
    case send = "chat.send"
    case title = "chat.title"
    case back = "chat.back"
    case stop = "chat.stop"
    case sendFailed = "chat.sendFailed"
    /// Label aksesibilitas tombol panah ke pesan terbaru.
    case scrollToLatest = "chat.scrollToLatest"
    case shortcutsTitle = "welcome.shortcutsTitle"
    /// Bagian yang bisa diketuk ditulis sebagai link Markdown; tujuannya diabaikan.
    case welcomeTerms = "welcome.terms"
    /// Label pengirim di atas bubble agen; statis, bukan nama agen dari gateway.
    case liveAgentSender = "liveAgent.sender"
    case liveAgentTyping = "liveAgent.typing"
    case leaveAgentQueue = "liveAgent.leaveQueue"
    /// Label aksesibilitas tombol lampiran saat dilayani agen.
    case liveAgentAttachment = "liveAgent.attachment"
    /// Chip abu saat agen bergabung dan saat sesi agen berakhir.
    case agentStartedChip = "liveAgent.started.chip"
    case agentEndedChip = "liveAgent.ended.chip"
    case agentConnectingTitle = "liveAgent.connecting.title"
    case agentConnectingMessage = "liveAgent.connecting.message"
    case agentEndedTitle = "liveAgent.ended.title"
    case agentEndedMessage = "liveAgent.ended.message"
    case agentCanceledTitle = "liveAgent.canceled.title"
    case agentCanceledMessage = "liveAgent.canceled.message"
    case agentUnavailableTitle = "liveAgent.unavailable.title"
    case agentUnavailableMessage = "liveAgent.unavailable.message"
    /// TODO: Copy sementara dari tim iOS; ganti dengan copy final UI/UX.
    case agentNotContinuedTitle = "liveAgent.notContinued.title"
    case agentNotContinuedMessage = "liveAgent.notContinued.message"
    /// Bottom sheet sumber lampiran setelah tombol `+` diketuk; judulnya `liveAgentAttachment`.
    case attachmentGallery = "attachment.gallery"
    case attachmentGalleryFormats = "attachment.gallery.formats"
    case attachmentFile = "attachment.file"
    case attachmentFileFormats = "attachment.file.formats"
    /// Label aksesibilitas grabber sheet.
    case attachmentClose = "attachment.close"
    /// TODO: Copy sementara dari tim iOS; ganti dengan copy final UI/UX.
    case attachmentUnsupportedFormat = "attachment.unsupportedFormat"

    case referenceLetterTitle = "referenceLetter.title"
    case referenceLetterConfirm = "referenceLetter.confirm"
    case referenceLetterCancel = "referenceLetter.cancel"
    case referenceLetterChoose = "referenceLetter.choose"
    case referenceLetterRequired = "referenceLetter.required"
    case referenceLetterPurpose = "referenceLetter.purpose"
    case referenceLetterFormat = "referenceLetter.format"
    case referenceLetterEmbassy = "referenceLetter.embassy"
    case referenceLetterAccounts = "referenceLetter.accounts"
    case referenceLetterCurrency = "referenceLetter.currency"
    case referenceLetterBalance = "referenceLetter.balance"
    case referenceLetterInvestment = "referenceLetter.investment"
    case referenceLetterLanguage = "referenceLetter.language"
    case referenceLetterEmail = "referenceLetter.email"
    case referenceLetterAddress = "referenceLetter.address"
    case referenceLetterAccountCount = "referenceLetter.accountCount"
    case referenceLetterRetry = "referenceLetter.retry"
    case referenceLetterPIN = "referenceLetter.PIN"
    case referenceLetterDeleteDigit = "referenceLetter.deleteDigit"
    case referenceLetterSubmitFailed = "referenceLetter.submitFailed"
    case referenceLetterComplete = "referenceLetter.complete"
    case referenceLetterCancelled = "referenceLetter.cancelled"
    case referenceLetterHistory = "referenceLetter.history"
}
