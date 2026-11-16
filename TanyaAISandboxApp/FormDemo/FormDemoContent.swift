//
//  FormDemoContent.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 12/11/26.
//

import DesignKit
import SwiftUI

/// Sandbox saja: form contoh `--form-demo` di ujung daftar chat. Format menentukan field berikutnya: hardcopy =
/// alamat, softcopy = email tersimpan yang tidak bisa diubah.
struct FormDemoContent: View {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors
    @ObservedObject var model: FormDemoModel

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            Text(String(SandboxCopy.formTitle, locale: locale))
                .designFont(.cardTitle)
                .foregroundColor(colors.colorsTextPrimaryDark)
            formatField
            accountsField
            deliveryField
            ToggleRow(label: String(SandboxCopy.formBalance, locale: locale), isOn: $model.isBalanceShown)
                .accessibilityIdentifier(SandboxOptions.formBalanceIdentifier)
            actions
        }
        .padding(FigmaSize.spacingLarge.scaledToArtwork)
        .cardStyle(isOutlined: false)
    }

    private var formatField: some View {
        SelectField(
            label: String(SandboxCopy.formFormat, locale: locale),
            value: formatTitle,
            placeholder: String(SandboxCopy.formFormatPlaceholder, locale: locale),
            error: error(for: .format, copy: .formRequiredChoice),
            onTap: { model.open(.format) }
        )
        .accessibilityIdentifier(SandboxOptions.formFormatIdentifier)
    }

    private var accountsField: some View {
        SelectField(
            label: String(SandboxCopy.formAccounts, locale: locale),
            value: accountsSummary,
            placeholder: String(SandboxCopy.formAccountsPlaceholder, locale: locale),
            error: error(for: .accounts, copy: .formRequiredChoice),
            onTap: { model.open(.accounts) }
        )
        .accessibilityIdentifier(SandboxOptions.formAccountsIdentifier)
    }

    private var actions: some View {
        HStack(spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            FilledButton(title: String(SandboxCopy.formCancel, locale: locale), variant: .outlined, onTap: model.cancel)
                .accessibilityIdentifier(SandboxOptions.formCancelIdentifier)
            FilledButton(title: String(SandboxCopy.formConfirm, locale: locale), onTap: model.confirm)
                .accessibilityIdentifier(SandboxOptions.formConfirmIdentifier)
        }
    }

    @ViewBuilder
    private var deliveryField: some View {
        if model.isHardcopy {
            TextInputField(
                label: String(SandboxCopy.formAddress, locale: locale),
                text: $model.address,
                placeholder: String(SandboxCopy.formAddressPlaceholder, locale: locale),
                error: error(for: .address, copy: .formRequiredText)
            )
            .accessibilityIdentifier(SandboxOptions.formAddressIdentifier)
        } else {
            TextInputField(
                label: String(SandboxCopy.formEmail, locale: locale),
                text: .constant(SandboxOptions.formEmail),
                placeholder: String(SandboxCopy.formEmail, locale: locale)
            )
            .disabled(true)
            .accessibilityIdentifier(SandboxOptions.formEmailIdentifier)
        }
    }
}

// MARK: - Helpers

private extension FormDemoContent {
    var formatTitle: String? {
        FormDemoSheetContent.formatOptions(locale: locale).first { $0.id == model.formatID }?.title
    }

    /// Satu rekening = namanya; lebih dari satu = jumlahnya.
    var accountsSummary: String? {
        let titles = SandboxOptions.formAccounts.filter { model.accountIDs.contains($0.id) }.map(\.title)
        guard !titles.dropFirst().isEmpty else { return titles.first }
        return String(format: String(SandboxCopy.formAccountsSelected, locale: locale), titles.count)
    }

    func error(for field: FormDemoField, copy: SandboxCopy) -> String? {
        model.invalidFields.contains(field) ? String(copy, locale: locale) : nil
    }
}
