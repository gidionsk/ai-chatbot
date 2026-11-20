//
//  ChatSheetModifier.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

import DesignKit
import SwiftUI

/// Semua bottom sheet halaman chat lewat satu `.bottomSheet(item:)` DesignKit di root halaman, supaya latar gelap
/// menutupi header dan composer: pilihan sumber lampiran lalu picker sistem untuk sumber yang dipilih, dan konfirmasi
/// End Session. Picker sistem tetap `.sheet` karena itu layar milik iOS, bukan isi sheet DesignKit. Sheet yang sudah
/// tidak berlaku ditutup sendiri: lampiran saat agen tidak melayani lagi, konfirmasi saat bar sesi agen hilang atau
/// antrean/sesinya berganti (mis. reconnect ke percakapan lain), supaya Yes tidak mengakhiri sesi lain.
@MainActor
struct ChatSheetModifier: ViewModifier {
    @Environment(\.locale) private var locale
    @Binding private var sheet: ChatSheet?
    /// Picker sistem yang sedang terbuka; nil = tertutup.
    @State private var source: ChatAttachmentSource?
    /// Sesi agen berakhir. Disimpan sebagai state karena callback picker sistem memegang salinan modifier dari saat
    /// picker dibuka, yang `isAttachable`-nya masih true; state selalu dibaca dari nilai terbaru.
    @State private var isSessionEnded = false
    /// Lampiran masih boleh dipilih (agen masih melayani).
    private let isAttachable: Bool
    /// Antrean atau sesi agen yang barnya tampil; nil = bar tidak tampil.
    private let agentSession: AgentSessionKey?
    private let onPick: (URL) -> Void
    private let onLeave: (AgentSessionKey) -> Void

    init(
        sheet: Binding<ChatSheet?>,
        isAttachable: Bool,
        agentSession: AgentSessionKey?,
        onPick: @escaping (URL) -> Void,
        onLeave: @escaping (AgentSessionKey) -> Void
    ) {
        _sheet = sheet
        self.isAttachable = isAttachable
        self.agentSession = agentSession
        self.onPick = onPick
        self.onLeave = onLeave
    }

    func body(content: Content) -> some View {
        content
            .bottomSheet(item: $sheet, closeLabel: String(ChatCopy.sheetClose, locale: locale)) { sheetContent($0) }
            .sheet(item: $source) { picker($0) }
            .onChange(of: isAttachable, perform: closeAttachment)
            .onChange(of: agentSession, perform: closeStaleConfirmation)
    }

    @ViewBuilder
    private func sheetContent(_ sheet: ChatSheet) -> some View {
        switch sheet {
        case .attachment(let isFormatRejected):
            AttachmentSourceSheet(isFormatRejected: isFormatRejected, onSelect: choose)
        case .leaveAgent(let session):
            ConfirmationPrompt(
                title: String(ChatCopy.leaveAgentConfirmTitle, locale: locale),
                message: String(ChatCopy.leaveAgentConfirmMessage, locale: locale),
                confirmTitle: String(ChatCopy.leaveAgentConfirm, locale: locale),
                cancelTitle: String(ChatCopy.leaveAgentCancel, locale: locale),
                onConfirm: { confirmLeave(session) },
                onCancel: close
            )
        }
    }

    @ViewBuilder
    private func picker(_ source: ChatAttachmentSource) -> some View {
        switch source {
        case .gallery:
            PhotoAttachmentPicker(onPick: onPick, onReject: rejectFormat, onDismiss: closePicker)
        case .file:
            DocumentAttachmentPicker(onPick: onPick, onDismiss: closePicker)
        }
    }
}

// MARK: - Helpers

private extension ChatSheetModifier {
    /// Sheet ditutup lalu picker sistem dibuka untuk sumber yang diketuk.
    func choose(_ source: ChatAttachmentSource) {
        sheet = nil
        self.source = source
    }

    /// Yes: sheet ditutup, `leave-agent` untuk antrean atau sesi saat End Session diketuk (dicek ulang bridge).
    func confirmLeave(_ session: AgentSessionKey) {
        sheet = nil
        onLeave(session)
    }

    func close() {
        sheet = nil
    }

    /// Pilihan Galeri / File dibuka lagi dengan pesan format, supaya nasabah bisa langsung memilih ulang.
    /// Tidak dibuka lagi bila sesi agen sudah berakhir selama picker tampil.
    func rejectFormat() {
        guard !isSessionEnded else { return }
        sheet = .attachment(isFormatRejected: true)
    }

    func closePicker() {
        source = nil
    }

    /// Sesi agen berakhir: sheet lampiran dan picker sistem ikut ditutup supaya lampiran tidak terpilih di mode bot.
    func closeAttachment(isStillAttachable: Bool) {
        isSessionEnded = !isStillAttachable
        guard !isStillAttachable else { return }
        source = nil
        guard case .attachment = sheet else { return }
        sheet = nil
    }

    /// Konfirmasi milik antrean atau sesi yang sudah tidak tampil ditutup.
    func closeStaleConfirmation(current: AgentSessionKey?) {
        guard case .leaveAgent(let session) = sheet, session != current else { return }
        sheet = nil
    }
}
