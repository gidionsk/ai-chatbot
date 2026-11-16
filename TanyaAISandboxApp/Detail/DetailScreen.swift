//
//  DetailScreen.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import DesignKit
import SwiftUI

/// Halaman host level kedua; membuka Tanya AI lewat coordinator miliknya sendiri.
@MainActor
struct DetailScreen: ScreenContent {
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DetailScreenViewModel
    let onOpenTanyaAI: () -> Void

    var body: some View {
        ScreenScaffold(
            title: String(SandboxCopy.detailTitle, locale: locale),
            backLabel: String(SandboxCopy.back, locale: locale),
            scrollProgress: .zero, onBack: { dismiss() },
            content: { page(headerHeight: $0) }, trailing: { EmptyView() }, footer: { EmptyView() },
            background: { EmptyView() }
        )
    }

    private func page(headerHeight: CGFloat) -> some View {
        HostButton(
            title: String(SandboxCopy.open, locale: locale),
            identifier: SandboxOptions.detailTanyaAIIdentifier, action: onOpenTanyaAI
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, FigmaSize.spacingLarge.scaledToArtwork)
        .padding(.top, headerHeight + FigmaSize.spacingLarge.scaledToArtwork)
    }
}
