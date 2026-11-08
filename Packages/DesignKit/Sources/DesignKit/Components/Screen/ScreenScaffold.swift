//
//  ScreenScaffold.swift
//  DesignKit
//
//  Created by Wendra on 5/11/26.
//

import SwiftUI

/// Kerangka halaman: header menimpa area konten, footer di bawahnya, dan latar di belakang semuanya. Scroll milik
/// konten, jadi pemilik scroll (mis. table) melaporkan `scrollProgress`. `content` menerima tinggi header supaya
/// bisa memberi inset awal.
@MainActor
public struct ScreenScaffold<Content: View, Trailing: View, Footer: View, Background: View>: View {
    @Environment(\.designColors) private var colors
    private let title: String
    private let backLabel: String
    private let scrollProgress: CGFloat
    private let onBack: () -> Void
    private let content: (CGFloat) -> Content
    private let trailing: Trailing
    private let footer: Footer
    private let background: Background

    public init(
        title: String, backLabel: String, scrollProgress: CGFloat, onBack: @escaping () -> Void,
        @ViewBuilder content: @escaping (CGFloat) -> Content, @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder footer: () -> Footer, @ViewBuilder background: () -> Background
    ) {
        self.title = title
        self.backLabel = backLabel
        self.scrollProgress = scrollProgress
        self.onBack = onBack
        self.content = content
        self.trailing = trailing()
        self.footer = footer()
        self.background = background()
    }

    public var body: some View {
        // Safe area atas dibaca sekali di root; header dan konten sendiri mulai dari tepi atas layar.
        GeometryReader { geometry in
            VStack(spacing: .zero) {
                surface(isNotched: ScreenHeader.isNotched(safeAreaTop: geometry.safeAreaInsets.top))
                footer
            }
        }
        .background(backdrop)
    }

    private var backdrop: some View {
        ZStack {
            colors.colorsSurfacePrimary
            background
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private func surface(isNotched: Bool) -> some View {
        ZStack(alignment: .top) {
            content(ScreenHeader.height(isNotched: isNotched))
            ScreenHeader(
                title: title, backLabel: backLabel, scrollProgress: scrollProgress, isNotched: isNotched,
                onBack: onBack, trailing: { trailing }
            )
        }
        .ignoresSafeArea(.container, edges: .top)
    }
}
