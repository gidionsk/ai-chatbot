//
//  ScreenContainer.swift
//  DesignKit
//
//  Created by Wendra on 16/10/26.
//

import Foundation
import SwiftUI

/// Shared scrolling screen layout. Supply content, not another vertical ScrollView.
/// Navigation callbacks and the footer's padding belong to the caller.
/// `background` (misalnya gambar latar) tampil di atas warna surface, di belakang header, konten dan footer.
@MainActor
public struct ScreenContainer<Content: View, Trailing: View, Footer: View, Background: View>: View {
    @Environment(\.designColors)
    private var colors
    // Keep the coordinate-space ID stable when the parent view updates.
    @State
    private var scrollSpaceID = UUID()
    /// 0 di posisi teratas sampai 1 setelah digulir setinggi header; header memudar sebanding nilai ini.
    @State
    private var scrollProgress: CGFloat = .zero
    @State private var viewportHeight: CGFloat = .zero
    @State private var isNearBottom = true
    private let title: String
    private let backLabel: String
    private let onBack: () -> Void
    private let content: Content
    private let trailing: Trailing
    private let footer: Footer
    private let background: Background

    public init(
        title: String, backLabel: String, onBack: @escaping () -> Void,
        @ViewBuilder content: () -> Content, @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder footer: () -> Footer, @ViewBuilder background: () -> Background
    ) {
        self.title = title
        self.backLabel = backLabel
        self.onBack = onBack
        self.content = content()
        self.trailing = trailing()
        self.footer = footer()
        self.background = background()
    }

    public var body: some View {
        // Safe area atas dibaca sekali di root; header dan scroll sendiri mulai dari tepi atas layar.
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

    private var viewportReader: some View {
        GeometryReader { geometry in
            Color.clear
                .onAppear { viewportHeight = geometry.size.height }
                .onChange(of: geometry.size.height) { viewportHeight = $0 }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func surface(isNotched: Bool) -> some View {
        let headerHeight = ScreenHeader.height(isNotched: isNotched)
        return ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: .zero) { content }
                    .environment(
                        \.screenViewport,
                        ScreenViewport(height: viewportHeight, headerHeight: headerHeight, isNearBottom: isNearBottom)
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, FigmaSize.spacingLarge.scaledToArtwork)
                    .padding(.top, headerHeight + FigmaSize.spacingLarge.scaledToArtwork)
                    .padding(.bottom, FigmaSize.spacingLarge.scaledToArtwork)
                    .onScrollProgressChange(in: scrollSpaceID, distance: headerHeight) {
                        scrollProgress = $0
                    }
                    .onScrollBottomChange(
                        in: scrollSpaceID, viewportHeight: viewportHeight,
                        distance: FigmaSize.spacingDoubleExtraLarge.scaledToArtwork
                    ) {
                        isNearBottom = $0
                    }
            }
            .coordinateSpace(name: scrollSpaceID)
            .background(viewportReader)
            ScreenHeader(
                title: title, backLabel: backLabel, scrollProgress: scrollProgress, isNotched: isNotched,
                onBack: onBack, trailing: { trailing }
            )
        }
        .ignoresSafeArea(.container, edges: .top)
    }
}

extension ScreenContainer where Background == EmptyView {
    public init(
        title: String, backLabel: String, onBack: @escaping () -> Void,
        @ViewBuilder content: () -> Content, @ViewBuilder trailing: () -> Trailing, @ViewBuilder footer: () -> Footer
    ) {
        self.init(
            title: title, backLabel: backLabel, onBack: onBack,
            content: content, trailing: trailing, footer: footer, background: { EmptyView() }
        )
    }
}

extension ScreenContainer where Trailing == EmptyView, Footer == EmptyView, Background == EmptyView {
    public init(
        title: String, backLabel: String, onBack: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.init(
            title: title, backLabel: backLabel, onBack: onBack,
            content: content, trailing: { EmptyView() }, footer: { EmptyView() }, background: { EmptyView() }
        )
    }
}
