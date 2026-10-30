//
//  ChatScreen.swift
//  TanyaAI
//
//  Created by Wendra on 15/10/26.
//

import DesignKit
import SwiftUI

/// The feature owns its header; the draft lives in ComposerSection. Content is injected.
/// `welcome` (dari BE) hanya tampil bila history kosong; sebelum history pertama selesai, loading di tengah.
/// Shortcut yang diketuk dikirim lewat `bridge` seperti chat.
/// Selama halaman tampil, `bridge` tersambung ke gateway. Setelah kirim, tombol menjadi titik bergerak sampai
/// pertanyaan datang dari stream, lalu stop sampai jawaban selesai; shortcut nonaktif selama menunggu.
@MainActor
public struct ChatScreen<Content: View>: View {
    @Environment(\.locale)
    private var locale
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.designColors)
    private var colors
    @ObservedObject
    private var bridge: TanyaAIBridge
    private let isEnabled: Bool
    private let welcome: WelcomeContent?
    private let onBack: (() -> Void)?
    private let content: Content

    public init(
        isEnabled: Bool = true, welcome: WelcomeContent? = nil, bridge: TanyaAIBridge,
        onBack: (() -> Void)? = nil, @ViewBuilder content: () -> Content
    ) {
        _bridge = ObservedObject(wrappedValue: bridge)
        self.isEnabled = isEnabled
        self.welcome = welcome
        self.onBack = onBack
        self.content = content()
    }

    public var body: some View {
        ScreenContainer(
            title: String(ChatCopy.title, locale: locale),
            backLabel: String(ChatCopy.back, locale: locale),
            onBack: close, content: { scrollContent }, trailing: { EmptyView() },
            footer: { composer },
            background: { backgroundImage }
        )
        .overlay { loadingIndicator }
        // Dibatalkan otomatis saat halaman hilang; tampil lagi = init ulang dan mengejar history.
        .task { await bridge.run() }
    }

    @ViewBuilder
    private var scrollContent: some View {
        if let welcome, bridge.isWelcomeVisible {
            WelcomeSection(content: welcome, isEnabled: isEnabled && isSendable, onSelect: select)
        }
        // TODO: Daftar pesan (`bridge.messages`) dengan bubble dan chip tanggal menyusul di PR tampilan pesan.
        content
    }

    /// Hanya saat pertama dibuka; menyambung ulang tidak menutupi pesan yang sudah tampil. Gagal permanen
    /// menghentikan loading; error ditampilkan host lewat `onConnectionFailed`/`onSessionExpired`.
    @ViewBuilder
    private var loadingIndicator: some View {
        if bridge.isLoadingHistory {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(colors.colorsIconColored)
                .accessibilityIdentifier(ChatElementIdentifier.loading)
        }
    }

    private var composer: some View {
        ComposerSection(
            isEnabled: isEnabled && bridge.isReady, phase: bridge.turnPhase, onSend: send, onStop: stop
        )
    }

    /// Menempel di atas layar selebar layar; bagian bawah yang tidak tertutup gambar memakai warna surface.
    /// Sengaja `scaledToFit`, bukan `scaledToFill` + `clipped`: di iOS 17 kombinasi itu membuat latar dan isi scroll
    /// hilang (putih) selama swipe back interaktif di host.
    private var backgroundImage: some View {
        Image(ChatImage.chatBackground).resizable()
            .scaledToFit()
            .frame(maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Actions

private extension ChatScreen {
    var isSendable: Bool { bridge.isReady && !bridge.isAwaitingReply }

    func close() {
        if let onBack { onBack() } else { dismiss() }
    }

    /// True bila gateway menerima pesan; pertanyaan tampil setelah datang lewat stream.
    func send(_ text: String) async -> Bool {
        await bridge.send(text)
    }

    /// Menghentikan jawaban yang sedang berjalan; kunci dibuka oleh `turn_end` dari stream.
    func stop() {
        Task { [bridge] in await bridge.cancelTurn() }
    }

    /// Shortcut dikirim sebagai chat; pertanyaan tampil setelah datang lewat stream.
    func select(_ shortcut: WelcomeShortcut) {
        Task { [bridge] in _ = await bridge.send(shortcut.prompt) }
    }
}
