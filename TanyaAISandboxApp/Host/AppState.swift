//
//  AppState.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import Foundation

/// Tiruan state aplikasi host. Sandbox mulai dalam keadaan login agar langsung ke main.
@MainActor
final class AppState: ObservableObject {
    enum State {
        case prelogin
        case loggedIn
    }

    @Published var state = State.loggedIn
}
