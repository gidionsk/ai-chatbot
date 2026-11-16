//
//  FormDemoSheetContent.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 12/11/26.
//

import DesignKit
import SwiftUI

/// Sandbox saja: isi bottom sheet form contoh. Format = satu pilihan; rekening = boleh lebih dari satu, daftarnya
/// datang setelah jeda seolah dari service host.
struct FormDemoSheetContent: View {
    @Environment(\.locale) private var locale
    @ObservedObject var model: FormDemoModel
    /// Daftar yang sedang dibuka; `.bottomSheet(item:)` membangun isi baru untuk nilai lain.
    let sheet: FormDemoSheet

    var body: some View {
        switch sheet {
        case .format:
            OptionList(
                title: String(SandboxCopy.formFormat, locale: locale),
                items: Self.formatOptions(locale: locale),
                selectedIDs: model.formatID.map { [$0] } ?? [],
                onSelect: model.selectFormat
            )
        case .accounts:
            OptionList(
                title: String(SandboxCopy.formAccounts, locale: locale),
                items: model.accountOptions,
                selectedIDs: model.accountIDs,
                mode: .multiple,
                confirmLabel: String(SandboxCopy.formChoose, locale: locale),
                onSelect: model.selectAccounts
            )
        }
    }

    static func formatOptions(locale: Locale) -> [OptionItem] {
        [
            OptionItem(id: SandboxOptions.formSoftcopyID, title: String(SandboxCopy.formSoftcopy, locale: locale)),
            OptionItem(id: SandboxOptions.formHardcopyID, title: String(SandboxCopy.formHardcopy, locale: locale))
        ]
    }
}
