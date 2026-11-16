//
//  ReferenceLetterOptions.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import DesignKit
import SwiftUI

/// Isi `.bottomSheet(item:)` yang dipasang caller di root halaman. Tidak membuat wadah sheet baru di dalam kartu.
@MainActor
public struct ReferenceLetterOptions: View {
    @Environment(\.locale) private var locale
    @Binding private var draft: ReferenceLetterDraft
    private let inquiry: ReferenceLetterInquiry
    private let field: ReferenceLetterFieldID
    private let onSelect: () -> Void

    public init(
        inquiry: ReferenceLetterInquiry,
        draft: Binding<ReferenceLetterDraft>,
        field: ReferenceLetterFieldID,
        onSelect: @escaping () -> Void
    ) {
        self.inquiry = inquiry
        self._draft = draft
        self.field = field
        self.onSelect = onSelect
    }

    public var body: some View {
        OptionList(
            title: String(field.label, locale: locale),
            items: field.options(in: inquiry),
            selectedIDs: draft.selectedCodes(for: field),
            mode: field.isMultiple ? .multiple : .single,
            confirmLabel: String(ChatCopy.referenceChoose, locale: locale),
            isEmptyAllowed: true
        ) { codes in
            draft.select(codes, for: field, inquiry: inquiry)
            onSelect()
        }
    }
}
