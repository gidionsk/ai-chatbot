//
//  Screen.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import SwiftUI

/// Tiruan base screen host: membungkus setiap halaman agar blocker host (no internet) berlaku.
@MainActor
struct Screen<Content: ScreenContent>: View {
    @ObservedObject private var contentViewModel: ScreenContentViewModel
    private let content: Content

    init(_ content: () -> Content) {
        let content = content()
        self.content = content
        contentViewModel = content.viewModel
    }

    var body: some View {
        ZStack {
            content
            if contentViewModel.isNetworkUnavailable {
                NetworkUnavailableView(onRetry: contentViewModel.retry)
            }
        }
        .navigationBarHidden(true)
    }
}
