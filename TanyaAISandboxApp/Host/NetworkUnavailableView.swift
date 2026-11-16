//
//  NetworkUnavailableView.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import DesignKit
import SwiftUI

/// Tiruan blocker no internet host yang menutup seluruh halaman.
@MainActor
struct NetworkUnavailableView: View {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            Text(String(SandboxCopy.offlineTitle, locale: locale))
                .foregroundColor(colors.colorsTextPrimaryDark)
            HostButton(
                title: String(SandboxCopy.offlineRetry, locale: locale),
                identifier: SandboxOptions.offlineRetryIdentifier, action: onRetry
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.colorsSurfacePrimary.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SandboxOptions.offlineIdentifier)
    }
}
