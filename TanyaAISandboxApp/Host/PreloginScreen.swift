//
//  PreloginScreen.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import DesignKit
import SwiftUI

/// Tiruan prelogin: cukup untuk membuktikan logout menutup Tanya AI.
@MainActor
struct PreloginScreen: View {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors
    @EnvironmentObject
    private var appState: AppState

    var body: some View {
        VStack(spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            Text(String(SandboxCopy.preloginTitle, locale: locale))
            HostButton(
                title: String(SandboxCopy.login, locale: locale),
                identifier: SandboxOptions.loginIdentifier
            ) { appState.state = .loggedIn }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.colorsSurfacePrimary.ignoresSafeArea())
    }
}
