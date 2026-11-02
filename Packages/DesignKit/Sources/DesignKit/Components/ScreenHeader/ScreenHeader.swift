//
//  ScreenHeader.swift
//  DesignKit
//
//  Created by Wendra on 16/10/26.
//

import SwiftUI

/// A centered title with equal action slots. The caller owns scroll state and navigation.
/// Ukuran mengikuti navigation bar host: header mulai dari tepi atas layar (caller menaruhnya tanpa
/// safe area atas), padding atas `CustomScreenInsets` tanpa scale, ikon 24, judul Fira Sans Bold 16.
/// Saat diam transparan, sehingga latar screen tembus sampai status bar. Selama konten digulir, latar putih,
/// bayangan Figma `Shadow/Default`, dan gradient tipis di bawahnya muncul bertahap sebanding `scrollProgress`
/// sehingga header terangkat seperti kartu tanpa berganti mendadak.
@MainActor
public struct ScreenHeader<Trailing: View>: View {
    @Environment(\.designColors)
    private var colors
    private let title: String
    private let backLabel: String
    private let scrollProgress: CGFloat
    private let isNotched: Bool
    private let fontFace: FontFace
    private let onBack: () -> Void
    private let trailing: Trailing

    /// `scrollProgress` 0 (transparan, di posisi teratas) sampai 1 (solid penuh). `isNotched` dari
    /// `ScreenHeader.isNotched(safeAreaTop:)`; menentukan padding atas dari tepi layar.
    public init(
        title: String, backLabel: String, scrollProgress: CGFloat, isNotched: Bool,
        fontFace: FontFace = .firaSansBold, onBack: @escaping () -> Void,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.backLabel = backLabel
        self.scrollProgress = scrollProgress
        self.isNotched = isNotched
        self.fontFace = fontFace
        self.onBack = onBack
        self.trailing = trailing()
    }

    public var body: some View {
        // Seperti host: judul selebar bar dengan padding sendiri, tombol di lapisan atasnya.
        ZStack {
            titleText
            HStack(spacing: .zero) {
                backButton
                Spacer(minLength: .zero)
                Color.clear.frame(width: actionSize, height: actionSize).overlay(trailing)
            }
        }
        .padding(.horizontal, CustomSizes.Header.horizontalPadding.scaledToArtwork)
        .padding(.top, isNotched ? CustomScreenInsets.headerTopWithNotch : CustomScreenInsets.headerTop)
        .padding(.bottom, CustomSizes.Header.bottomPadding.scaledToArtwork)
        .background(surface)
        // Di belakang surface, supaya bayangan header tetap tergambar di atas gradient.
        .background(alignment: .bottom) { fade }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(isScrolled ? ComponentIdentifier.Header.scrolled : ComponentIdentifier.Header.root)
    }

    private var titleText: some View {
        Text(title)
            .font(fontFace.swiftUIFont(size: FigmaSize.typographySizeDisplayNormal16.scaledToArtwork))
            .foregroundColor(colors.colorsTextPrimaryDark)
            .multilineTextAlignment(.center)
            .lineLimit(CustomTextLines.headerTitle)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, FigmaSize.spacingExtraLarge.scaledToArtwork)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier(ComponentIdentifier.Header.title)
    }

    private var backButton: some View {
        Button(action: onBack) {
            Image(DesignIcon.backArrow).resizable().scaledToFit()
                .frame(
                    width: actionSize,
                    height: actionSize
                )
                .foregroundColor(colors.colorsIconColored)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(backLabel)
        .accessibilityIdentifier(ComponentIdentifier.Header.back)
    }

    /// Bayangan digambar di luar frame: tinggi header tetap dan sentuhan tidak tertangkap. Bayangan mengikuti
    /// alpha surface, jadi ikut memudar dan tidak terlihat saat diam (transparan penuh).
    private var surface: some View {
        colors.colorsSurfacePrimary.opacity(scrollProgress).designShadow()
    }

    /// Di luar frame header: tidak mengubah tinggi header dan tidak menangkap sentuhan.
    @ViewBuilder
    private var fade: some View {
        if isScrolled {
            LinearGradient(
                colors: [colors.colorsSurfacePrimary, colors.colorsSurfacePrimary.opacity(.zero)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: FigmaSize.spacingLarge.scaledToArtwork)
            .offset(y: FigmaSize.spacingLarge.scaledToArtwork)
            .opacity(scrollProgress)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

// MARK: - Helpers

private extension ScreenHeader {
    var actionSize: CGFloat { FigmaSize.weightIconSmall.scaledToArtwork }

    /// Sudah tidak di posisi teratas; dipakai identifier UI test dan untuk tidak membuat gradient saat diam.
    var isScrolled: Bool { scrollProgress > .zero }
}

extension ScreenHeader where Trailing == EmptyView {
    public init(
        title: String, backLabel: String, scrollProgress: CGFloat, isNotched: Bool,
        fontFace: FontFace = .firaSansBold, onBack: @escaping () -> Void
    ) {
        self.init(
            title: title, backLabel: backLabel, scrollProgress: scrollProgress, isNotched: isNotched,
            fontFace: fontFace, onBack: onBack, trailing: { EmptyView() }
        )
    }

    /// Notch / Dynamic Island bila safe area atas melebihi status bar klasik. Memakai safe area atas,
    /// bukan bawah seperti host, supaya keyboard (yang menambah inset bawah) tidak menggeser header.
    public static func isNotched(safeAreaTop: CGFloat) -> Bool {
        safeAreaTop > CustomScreenInsets.classicStatusBar
    }

    /// Tinggi header dari tepi atas layar; konten di bawah header mulai setelah nilai ini.
    public static func height(isNotched: Bool) -> CGFloat {
        (isNotched ? CustomScreenInsets.headerTopWithNotch : CustomScreenInsets.headerTop)
            + FigmaSize.weightIconSmall.scaledToArtwork
            + CustomSizes.Header.bottomPadding.scaledToArtwork
    }
}
