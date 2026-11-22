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
/// End Session. Picker sistem tetap `.sheet` karena itu layar milik iOS, bukan isi sheet DesignKit. Keduanya terikat ke
/// sesi agen saat dibuka; sheet dan picker yang sudah tidak berlaku ditutup sendiri: lampiran saat agen tidak melayani
/// lagi atau sesinya berganti (mis. reconnect ke percakapan lain yang juga dilayani agen), konfirmasi saat bar sesi
/// agen hilang atau sesinya berganti, supaya lampiran atau Yes tidak terbawa ke sesi lain.
@MainActor
struct ChatSheetModifier: ViewModifier {
    @Environment(\.locale) private var locale
    @Binding private var sheet: ChatSheet?
    /// Picker sistem yang sedang terbuka; nil = tertutup.
    @State private var source: ChatAttachmentSource?
    /// Sesi agen pemilik picker yang masih berlaku; nil = tidak ada. Callback picker membawa sesinya sendiri dan
    /// membandingkannya dengan nilai ini. Disimpan sebagai state karena callback picker sistem memegang salinan
    /// modifier dari saat picker dibuka; state selalu dibaca dari nilai terbaru, jadi hasil picker lama (mis. foto
    /// yang masih dimuat) tidak lolos setelah picker sesi lain dibuka.
    @State private var pickerSession: AgentSessionKey?
    /// Sesi agen yang sedang melayani, tempat lampiran boleh dipilih; nil = lampiran tidak tersedia.
    private let attachmentSession: AgentSessionKey?
    /// Antrean atau sesi agen yang barnya tampil; nil = bar tidak tampil.
    private let leaveSession: AgentSessionKey?
    private let onPick: (URL) -> Void
    private let onLeave: (AgentSessionKey) -> Void

    init(
        sheet: Binding<ChatSheet?>,
        attachmentSession: AgentSessionKey?,
        leaveSession: AgentSessionKey?,
        onPick: @escaping (URL) -> Void,
        onLeave: @escaping (AgentSessionKey) -> Void
    ) {
        _sheet = sheet
        self.attachmentSession = attachmentSession
        self.leaveSession = leaveSession
        self.onPick = onPick
        self.onLeave = onLeave
    }

    func body(content: Content) -> some View {
        content
            .bottomSheet(item: $sheet, closeLabel: String(ChatCopy.sheetClose, locale: locale)) { sheetContent($0) }
            .sheet(item: $source) { picker($0) }
            .onChange(of: attachmentSession) { closeStale(attachmentSession: $0, leaveSession: leaveSession) }
            .onChange(of: leaveSession) { closeStale(attachmentSession: attachmentSession, leaveSession: $0) }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: ChatSheet) -> some View {
        switch sheet {
        case .attachment(let session, let isFormatRejected):
            AttachmentSourceSheet(isFormatRejected: isFormatRejected) { choose($0, for: session) }
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

    /// Sesi picker ditangkap saat callback dibuat, bukan dibaca saat hasilnya tiba.
    @ViewBuilder
    private func picker(_ source: ChatAttachmentSource) -> some View {
        let session = pickerSession
        switch source {
        case .gallery:
            PhotoAttachmentPicker(
                onPick: { deliver($0, from: session) },
                onReject: { rejectFormat(from: session) },
                onDismiss: closePicker
            )
        case .file:
            DocumentAttachmentPicker(onPick: { deliver($0, from: session) }, onDismiss: closePicker)
        }
    }
}

// MARK: - Helpers

private extension ChatSheetModifier {
    /// Sheet ditutup lalu picker sistem dibuka untuk sumber yang diketuk, terikat ke sesi sheet-nya.
    func choose(_ source: ChatAttachmentSource, for session: AgentSessionKey) {
        sheet = nil
        pickerSession = session
        self.source = source
    }

    /// File dari picker yang sesinya sudah berganti atau berakhir (termasuk saat picker sesi lain sudah dibuka)
    /// dibuang, tidak diteruskan.
    func deliver(_ file: URL, from session: AgentSessionKey?) {
        guard let session, session == pickerSession else {
            return FileManager.default.discardChatAttachment(at: file)
        }
        onPick(file)
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
    /// Tidak dibuka lagi bila sesi agen sudah berganti atau berakhir selama picker tampil.
    func rejectFormat(from session: AgentSessionKey?) {
        guard let session, session == pickerSession else { return }
        sheet = .attachment(session, isFormatRejected: true)
    }

    func closePicker() {
        source = nil
    }

    /// Sesi agen berakhir atau berganti: picker sistem dan sheet milik sesi lama ikut ditutup, supaya lampiran tidak
    /// terpilih di mode bot atau di sesi lain dan Yes tidak mengakhiri sesi lain.
    func closeStale(attachmentSession: AgentSessionKey?, leaveSession: AgentSessionKey?) {
        if let pickerSession, pickerSession != attachmentSession {
            self.pickerSession = nil
            source = nil
        }
        guard let sheet, !sheet.isCurrent(attachmentSession: attachmentSession, leaveSession: leaveSession) else {
            return
        }
        self.sheet = nil
    }
}
