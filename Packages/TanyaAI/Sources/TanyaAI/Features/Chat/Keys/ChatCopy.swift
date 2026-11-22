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
    /// Label VoiceOver titik berdenyut di bawah pertanyaan selama bot menyiapkan jawaban; tidak tampil di layar.
    /// TODO: Copy sementara dari tim iOS; ganti dengan copy final UI/UX.
    case answerLoading = "chat.answerLoading"
    case shortcutsTitle = "welcome.shortcutsTitle"
    /// Bagian yang bisa diketuk ditulis sebagai link Markdown; tujuannya diabaikan.
    case welcomeTerms = "welcome.terms"
    /// Label pengirim di atas bubble agen; statis, bukan nama agen dari gateway.
    case liveAgentSender = "liveAgent.sender"
    case liveAgentTyping = "liveAgent.typing"
    case leaveAgentQueue = "liveAgent.leaveQueue"
    /// Bar di bawah header selama dilayani agen (Figma). TODO: Copy final id/zh dari UI/UX; sementara copy Figma.
    case agentSessionBanner = "liveAgent.session.banner"
    case endAgentSession = "liveAgent.session.end"
    /// Bottom sheet konfirmasi setelah End Session diketuk (Figma). TODO: Copy final id/zh dari UI/UX; sementara copy
    /// Figma seperti bar sesi agen.
    case leaveAgentConfirmTitle = "liveAgent.leaveConfirm.title"
    case leaveAgentConfirmMessage = "liveAgent.leaveConfirm.message"
    case leaveAgentConfirm = "liveAgent.leaveConfirm.confirm"
    case leaveAgentCancel = "liveAgent.leaveConfirm.cancel"
    /// Label aksesibilitas tombol lampiran saat dilayani agen.
    case liveAgentAttachment = "liveAgent.attachment"
    case agentConnectingTitle = "liveAgent.connecting.title"
    case agentConnectingMessage = "liveAgent.connecting.message"
    case agentConnectedTitle = "liveAgent.connected.title"
    case agentConnectedMessage = "liveAgent.connected.message"
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
    /// Label aksesibilitas grabber bottom sheet halaman chat (lampiran dan konfirmasi End Session).
    case sheetClose = "sheet.close"
    /// TODO: Copy sementara dari tim iOS; ganti dengan copy final UI/UX.
    case attachmentUnsupportedFormat = "attachment.unsupportedFormat"
}
