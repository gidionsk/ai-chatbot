//
//  SheetDemoContent.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 12/11/26.
//

import DesignKit
import SwiftUI

/// Sandbox saja: tombol di area scroll yang membuka bottom sheet contoh (`--sheet-demo`). Bukan flow chat.
struct SheetDemoContent: View {
    @Environment(\.locale) private var locale
    let onOpen: () -> Void

    var body: some View {
        FilledLinkButton(title: String(SandboxCopy.sheetOpen, locale: locale), onTap: onOpen)
            .accessibilityIdentifier(SandboxOptions.sheetOpenIdentifier)
    }
}
