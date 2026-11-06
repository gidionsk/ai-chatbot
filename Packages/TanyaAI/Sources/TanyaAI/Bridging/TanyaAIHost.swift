//
//  TanyaAIHost.swift
//  TanyaAI
//
//  Created by Wendra on 15/10/26.
//

import DesignKit
import SwiftUI

/// Konfigurasi dan pembuat halaman Tanya AI dalam SwiftUI. Host menampilkan `makeView()` lewat
/// navigasinya sendiri, misalnya sebagai tujuan `NavigationLink`; halaman berikutnya milik host.
/// `locale` dan `colors` dibaca saat view dibuat, jadi perubahan berlaku saat dibuka berikutnya.
@MainActor
public struct TanyaAIHost {
    /// Bahasa fitur, misalnya dari Localize_Swift milik host.
    public var locale: Locale
    /// Palette fitur dari hasil inquiry proposition; sebelum itu memakai palette default.
    public var colors: any FigmaColorProtocol
    private let isEnabled: Bool
    private let welcome: WelcomeContent?
    private let bridge: TanyaAIBridge

    /// `welcome` dipetakan host dari inquiry init BE. `bridge` dibuat sekali oleh host dan dipakai ulang
    /// setiap render, sehingga status menunggu jawaban tidak hilang saat halaman host di-render ulang.
    public init(
        locale: Locale = .current, colors: any FigmaColorProtocol = EnvironmentValues().designColors,
        isEnabled: Bool = true, welcome: WelcomeContent? = nil, bridge: TanyaAIBridge
    ) {
        self.locale = locale
        self.colors = colors
        self.isEnabled = isEnabled
        self.welcome = welcome
        self.bridge = bridge
    }

    /// Halaman Tanya AI. Tanpa `onBack`, tombol kembali memakai `dismiss` SwiftUI (pop pada navigasi host).
    /// `onOpenLink` menerima link yang diketuk di jawaban bot: host mengarahkan web ke webview-nya dan deeplink
    /// ke handler-nya. TanyaAI tidak pernah membuka Safari sendiri. `onOpenTerms` membuka halaman syarat & ketentuan
    /// milik host saat tautan di sambutan diketuk; tanpa handler ini, kalimat syarat & ketentuan tidak tampil.
    public func makeView(
        onBack: (() -> Void)? = nil, onOpenLink: @escaping (URL) -> Void = { _ in }, onOpenTerms: (() -> Void)? = nil
    ) -> some View {
        makeView(onBack: onBack, onOpenLink: onOpenLink, onOpenTerms: onOpenTerms) { EmptyView() }
    }

    /// Sama seperti di atas, dengan konten SwiftUI untuk area scroll (fixture UI atau konten fitur).
    public func makeView<Content: View>(
        onBack: (() -> Void)? = nil, onOpenLink: @escaping (URL) -> Void = { _ in }, onOpenTerms: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ChatScreen(
            isEnabled: isEnabled, welcome: welcome, bridge: bridge, onBack: onBack, onOpenLink: onOpenLink,
            onOpenTerms: onOpenTerms, content: content
        )
        .environment(\.locale, locale)
        .designColors(colors)
        // Starter mengikuti light palette Figma; dibatasi ke halaman ini, tidak mengubah host.
        .environment(\.colorScheme, .light)
    }
}
