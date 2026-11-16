//
//  ScreenContentViewModel.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import Foundation

/// Tiruan base view model host. State blocker dimiliki tiap halaman, bukan global.
class ScreenContentViewModel: ObservableObject {
    @Published private(set) var isNetworkUnavailable = false

    /// Sandbox: setiap error dianggap tidak ada internet.
    func didReceiveError(_ error: Error) {
        isNetworkUnavailable = true
    }

    func retry() {
        isNetworkUnavailable = false
    }
}
