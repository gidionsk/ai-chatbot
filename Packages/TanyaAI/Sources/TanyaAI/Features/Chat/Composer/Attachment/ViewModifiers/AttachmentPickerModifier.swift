//
//  AttachmentPickerModifier.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import DesignKit
import SwiftUI

/// Pilihan sumber lampiran di bottom sheet DesignKit, lalu picker sistem untuk sumber yang dipilih. Dipasang di root
/// halaman supaya latar gelap sheet menutupi header dan composer. Picker sistem tetap dibuka lewat `.sheet` karena
/// itu layar milik iOS, bukan isi sheet DesignKit.
/// TODO: Tampilan isi sheet sementara memakai `OptionList` (judul, baris dengan keterangan format) sampai ada Figma.
/// Isi sheet lampiran dan intent memakai presenter yang sama.
@MainActor
struct AttachmentPickerModifier<IntentSheet: View>: ViewModifier {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors
    @Binding var sheet: ChatBottomSheet?
    /// Picker sistem yang sedang terbuka; nil = tertutup.
    @State private var source: ChatAttachmentSource?
    /// Foto terakhir dari galeri ditolak karena formatnya; sheet dibuka lagi dengan pesan error.
    @State private var isFormatRejected = false
    /// Sesi agen berakhir. Disimpan sebagai state karena callback picker sistem memegang salinan modifier dari saat
    /// picker dibuka, yang `isAvailable`-nya masih true; state selalu dibaca dari nilai terbaru.
    @State private var isSessionEnded = false
    /// Lampiran masih boleh dipilih (agen masih melayani).
    let isAvailable: Bool
    let isDismissable: Bool
    let intentSheet: (ChatBottomSheet) -> IntentSheet
    let onPick: (URL) -> Void

    func body(content: Content) -> some View {
        content
            .bottomSheet(
                item: $sheet,
                closeLabel: String(ChatCopy.attachmentClose, locale: locale),
                isDismissable: isDismissable
            ) { item in
                if item == .attachment {
                    VStack(alignment: .leading, spacing: .zero) {
                        OptionList(
                            title: String(ChatCopy.liveAgentAttachment, locale: locale),
                            items: items,
                            onSelect: choose
                        )
                        formatError
                    }
                } else {
                    intentSheet(item)
                }
            }
            .sheet(item: $source) { picker($0) }
            .onChange(of: isPresented) { isShown in
                // Pesan format hanya untuk pilihan ulang tepat setelah ditolak, bukan saat sheet dibuka berikutnya.
                guard !isShown, source == nil else { return }
                isFormatRejected = false
            }
            .onChange(of: isAvailable) { isStillAvailable in
                // Sesi agen berakhir: sheet dan picker sistem ikut ditutup supaya lampiran tidak terpilih di mode bot.
                isSessionEnded = !isStillAvailable
                guard !isStillAvailable else { return }
                if isPresented { sheet = nil }
                source = nil
            }
    }

    /// TODO: Copy dan posisi pesan sementara sampai ada desain UI/UX.
    @ViewBuilder
    private var formatError: some View {
        if isFormatRejected {
            Text(String(ChatCopy.attachmentUnsupportedFormat, locale: locale))
                .designFont(.caption)
                .foregroundColor(colors.colorsTextNegative)
                .fixedSize(horizontal: false, vertical: true)
                .padding([.horizontal, .bottom], FigmaSize.spacingLarge.scaledToArtwork)
                .accessibilityIdentifier(ChatElementIdentifier.attachmentFormatError)
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

private extension AttachmentPickerModifier {
    var isPresented: Bool { sheet == .attachment }
    var items: [OptionItem] {
        ChatAttachmentSource.allCases.map { source in
            OptionItem(
                id: source.optionID,
                title: String(source.title, locale: locale),
                subtitle: String(source.formats, locale: locale)
            )
        }
    }

    /// Sheet ditutup lalu picker sistem dibuka untuk sumber yang diketuk.
    func choose(_ ids: [String]) {
        sheet = nil
        isFormatRejected = false
        source = ChatAttachmentSource.allCases.first { $0.optionID == ids.first }
    }

    /// Pilihan Galeri / File dibuka lagi dengan pesan format, supaya nasabah bisa langsung memilih ulang.
    /// Tidak dibuka lagi bila sesi agen sudah berakhir selama picker tampil.
    func rejectFormat() {
        guard !isSessionEnded else { return }
        isFormatRejected = true
        guard sheet == nil else { return }
        sheet = .attachment
    }

    func closePicker() {
        source = nil
    }
}
