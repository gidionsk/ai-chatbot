//
//  SheetDemoSheetContent.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 14/11/26.
//

import DesignKit
import SwiftUI

/// Sandbox saja: isi bottom sheet contoh (`--sheet-demo`). `--sheet-long` = baris lebih panjang dari layar,
/// `--sheet-multi` = pilihan banyak dengan tombol yang menempel di bawah sheet, `--sheet-input` = field teks di atas
/// daftar untuk mencoba sheet bersama keyboard.
struct SheetDemoSheetContent: View {
    @Environment(\.locale) private var locale
    @State private var note = String()
    let selectedIDs: [String]
    let onSelect: ([String]) -> Void

    var body: some View {
        inputField
        OptionList(
            title: String(SandboxCopy.sheetTitle, locale: locale),
            items: options,
            selectedIDs: selectedIDs,
            mode: SandboxOptions.current.isSheetMulti ? .multiple : .single,
            confirmLabel: String(SandboxCopy.sheetChoose, locale: locale),
            onSelect: onSelect
        )
    }

    @ViewBuilder
    private var inputField: some View {
        if SandboxOptions.current.isSheetInput {
            TextInputField(text: $note, placeholder: String(SandboxCopy.sheetInput, locale: locale))
                .accessibilityIdentifier(SandboxOptions.sheetInputIdentifier)
                .padding(.horizontal, FigmaSize.spacingLarge.scaledToArtwork)
                .padding(.bottom, FigmaSize.spacingLarge.scaledToArtwork)
        }
    }

    private var options: [OptionItem] {
        let isLong = SandboxOptions.current.isSheetLong
        let count = isLong ? SandboxOptions.sheetLongOptionCount : SandboxOptions.sheetOptionCount
        let title = String(SandboxCopy.sheetOption, locale: locale)
        return (Int.zero..<count).map { OptionItem(id: String($0), title: title) }
    }
}
