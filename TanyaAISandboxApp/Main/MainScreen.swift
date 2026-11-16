//
//  MainScreen.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import DesignKit
import SwiftUI

/// Tiruan main host. Aksi navigasi diteruskan ke coordinator lewat callback.
@MainActor
struct MainScreen: ScreenContent {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors
    @EnvironmentObject
    private var appState: AppState
    @ObservedObject var viewModel: MainScreenViewModel
    let onOpenDetail: () -> Void
    let onOpenTanyaAI: () -> Void

    var body: some View {
        VStack(spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            Text(String(SandboxCopy.mainTitle, locale: locale))
                .designFont(.cardTitle)
            actions
        }
        .foregroundColor(colors.colorsTextPrimaryDark)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.colorsSurfacePrimary.ignoresSafeArea())
    }

    @ViewBuilder
    private var actions: some View {
        HostButton(
            title: String(SandboxCopy.open, locale: locale),
            identifier: SandboxOptions.openIdentifier, action: onOpenTanyaAI
        )
        HostButton(
            title: String(SandboxCopy.detailOpen, locale: locale),
            identifier: SandboxOptions.detailOpenIdentifier, action: onOpenDetail
        )
        HostButton(
            title: String(SandboxCopy.offlineSimulate, locale: locale),
            identifier: SandboxOptions.offlineSimulateIdentifier
        ) { viewModel.didReceiveError(URLError(.notConnectedToInternet)) }
        HostButton(
            title: String(SandboxCopy.logout, locale: locale),
            identifier: SandboxOptions.logoutIdentifier
        ) { appState.state = .prelogin }
    }
}
