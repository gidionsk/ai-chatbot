//
//  AttachmentSourceSheet.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

import DesignKit
import SwiftUI

/// Isi bottom sheet sumber lampiran: Galeri dan File dengan keterangan format, lalu pesan merah bila foto galeri
/// terakhir ditolak karena formatnya.
/// TODO: Tampilan sementara memakai `OptionList` (judul, baris dengan keterangan format) sampai ada Figma; copy dan
/// posisi pesan format juga sementara sampai ada desain UI/UX.
@MainActor
struct AttachmentSourceSheet: View {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors
    let isFormatRejected: Bool
    let onSelect: (ChatAttachmentSource) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            OptionList(title: String(ChatCopy.liveAgentAttachment, locale: locale), items: items, onSelect: select)
            formatError
        }
    }

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
}

// MARK: - Helpers

private extension AttachmentSourceSheet {
    var items: [OptionItem] {
        ChatAttachmentSource.allCases.map { source in
            OptionItem(
                id: source.optionID,
                title: String(source.title, locale: locale),
                subtitle: String(source.formats, locale: locale)
            )
        }
    }

    func select(_ ids: [String]) {
        guard let source = ChatAttachmentSource.allCases.first(where: { $0.optionID == ids.first }) else { return }
        onSelect(source)
    }
}
