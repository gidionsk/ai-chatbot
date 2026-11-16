//
//  ReferenceLetterForm.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import DesignKit
import SwiftUI

/// Form surat referensi, disusun dari komponen DesignKit existing. Draft, validasi, dan aksi service milik caller.
/// Pasang sheet pilihan di root halaman menggunakan `ReferenceLetterOptions`; draft tidak hidup di sel table.
@MainActor
public struct ReferenceLetterForm: View {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors
    @Binding private var draft: ReferenceLetterDraft
    private let inquiry: ReferenceLetterInquiry
    private let invalidFields: Set<ReferenceLetterFieldID>
    private let onOpenOptions: (ReferenceLetterFieldID) -> Void
    private let onSubmit: (() -> Void)?

    public init(
        inquiry: ReferenceLetterInquiry,
        draft: Binding<ReferenceLetterDraft>,
        invalidFields: Set<ReferenceLetterFieldID> = [],
        onOpenOptions: @escaping (ReferenceLetterFieldID) -> Void,
        onSubmit: (() -> Void)? = nil
    ) {
        self.inquiry = inquiry
        self._draft = draft
        self.invalidFields = invalidFields
        self.onOpenOptions = onOpenOptions
        self.onSubmit = onSubmit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            if !inquiry.introduction.isEmpty {
                Text(inquiry.introduction).designFont(.body)
            }
            card
        }
        .foregroundColor(colors.colorsTextPrimaryDark)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            Text(String(ChatCopy.referenceTitle, locale: locale)).designFont(.cardTitle)
            choice(.purpose)
            choice(.documentFormat)
            TextInputField(
                label: String(ChatCopy.referenceDestination, locale: locale),
                text: $draft.destination,
                placeholder: String(ChatCopy.referenceDestination, locale: locale),
                error: error(for: .destination)
            )
            .accessibilityIdentifier(ChatElementIdentifier.referenceDestination)
            choice(.accounts)
            choice(.currency)
            choice(.language)
            ToggleRow(label: String(ChatCopy.referenceBalance, locale: locale), isOn: $draft.isBalanceShown)
            ToggleRow(label: String(ChatCopy.referenceInvestment, locale: locale), isOn: $draft.isInvestmentShown)
            delivery
            FilledButton(title: String(ChatCopy.referenceSend, locale: locale), onTap: { onSubmit?() })
                .disabled(onSubmit == nil)
                .accessibilityIdentifier(ChatElementIdentifier.referenceSend)
        }
        .padding(FigmaSize.spacingLarge.scaledToArtwork)
        .cardStyle(isOutlined: false)
    }

    private func choice(_ field: ReferenceLetterFieldID) -> some View {
        SelectField(
            label: String(field.label, locale: locale),
            value: summary(for: field),
            placeholder: String(ChatCopy.referencePlaceholder, locale: locale),
            error: error(for: field),
            onTap: { onOpenOptions(field) }
        )
        .accessibilityIdentifier(ChatElementIdentifier.referenceField(field))
    }

    @ViewBuilder
    private var delivery: some View {
        switch ReferenceLetterDocumentFormat(rawValue: draft.documentFormatCode ?? String()) {
        case .softcopy:
            TextInputField(
                label: String(ChatCopy.referenceEmail, locale: locale),
                text: .constant(inquiry.decryptedEmail),
                placeholder: String(),
                keyboard: .emailAddress
            )
            .disabled(true)
            .accessibilityIdentifier(ChatElementIdentifier.referenceEmail)
        case .hardcopy:
            TextInputField(
                label: String(ChatCopy.referenceAddress, locale: locale),
                text: .constant(inquiry.address),
                placeholder: String()
            )
            .disabled(true)
            .accessibilityIdentifier(ChatElementIdentifier.referenceAddress)
        case nil:
            EmptyView()
        }
    }
}

// MARK: - Helpers

private extension ReferenceLetterForm {
    func summary(for field: ReferenceLetterFieldID) -> String? {
        let selected = Set(draft.selectedCodes(for: field))
        let titles = field.options(in: inquiry).filter { selected.contains($0.id) }.map(\.title)
        guard !titles.isEmpty else { return nil }
        return titles.joined(separator: String(ChatCopy.referenceSeparator, locale: locale))
    }

    func error(for field: ReferenceLetterFieldID) -> String? {
        guard invalidFields.contains(field) else { return nil }
        return String(ChatCopy.referenceRequired, locale: locale)
    }
}
