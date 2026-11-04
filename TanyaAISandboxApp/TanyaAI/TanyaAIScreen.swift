//
//  TanyaAIScreen.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import SwiftUI

/// Konten halaman Tanya AI di host: view SwiftUI dari package, tanpa pembungkus UIKit. Link dari jawaban bot
/// diteruskan ke host; sandbox menampilkan URL-nya sebagai pengganti webview/deeplink host.
@MainActor
struct TanyaAIScreen: ScreenContent {
    @Environment(\.locale)
    private var locale
    @ObservedObject
    var viewModel: TanyaAIScreenViewModel
    @State
    private var openedLink: URL?
    let onBack: () -> Void

    var body: some View {
        page
            .alert(
                String(SandboxCopy.linkTitle, locale: locale), isPresented: isLinkPresented, presenting: openedLink,
                actions: { _ in Button(String(SandboxCopy.linkClose, locale: locale)) {} },
                message: { Text($0.absoluteString) }
            )
    }

    @ViewBuilder
    private var page: some View {
        let host = viewModel.host
        // Sandbox: mode --header-demo mengisi area scroll dengan konten contoh.
        if SandboxOptions.current.isHeaderDemo {
            host.makeView(onBack: onBack, onOpenLink: openLink) { HeaderDemoContent() }
        } else {
            host.makeView(onBack: onBack, onOpenLink: openLink)
        }
    }

    private var isLinkPresented: Binding<Bool> {
        Binding(get: { openedLink != nil }, set: { if !$0 { openedLink = nil } })
    }

    private func openLink(_ url: URL) {
        openedLink = url
    }
}
