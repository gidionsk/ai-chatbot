//
//  HostButton.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import DesignKit
import SwiftUI

/// Tombol sederhana halaman tiruan host.
@MainActor
struct HostButton: View {
    @Environment(\.designColors) private var colors
    let title: String
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .designFont(.bodyStrong)
                .foregroundColor(colors.colorsTextBrand)
        }
        .accessibilityIdentifier(identifier)
    }
}
