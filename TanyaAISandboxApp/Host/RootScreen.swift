//
//  RootScreen.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import SwiftUI

/// Tiruan root host: prelogin tetap hidup, main dibuang saat logout (seperti `setHidden` dengan `isRemove`).
@MainActor
struct RootScreen: View {
    @ObservedObject var appState: AppState

    var body: some View {
        ZStack {
            PreloginScreen()
            if appState.state == .loggedIn {
                MainCoordinator()
            }
        }
        .environmentObject(appState)
    }
}
