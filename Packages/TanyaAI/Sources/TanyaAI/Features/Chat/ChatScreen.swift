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
/// Selama halaman tampil, `bridge` tersambung ke gateway. Setelah kirim, bubble pertanyaan langsung tampil dan
/// tombol menjadi stop sampai jawaban selesai; shortcut nonaktif selama menunggu.
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
    @State private var scrollProgress = CGFloat.zero
    private let isEnabled: Bool
    private let welcome: WelcomeContent?
    private let onBack: (() -> Void)?
    private let onOpenLink: (String) -> Void
    private let content: Content

    public init(
        isEnabled: Bool = true, welcome: WelcomeContent? = nil, bridge: TanyaAIBridge,
        onBack: (() -> Void)? = nil, onOpenLink: @escaping (String) -> Void = { _ in },
        @ViewBuilder content: () -> Content
    ) {
        _bridge = ObservedObject(wrappedValue: bridge)
        self.isEnabled = isEnabled
        self.welcome = welcome
        self.onBack = onBack
        self.onOpenLink = onOpenLink
        self.content = content()
    }

    public var body: some View {
        ScreenScaffold(
            title: String(ChatCopy.title, locale: locale),
            backLabel: String(ChatCopy.back, locale: locale),
            scrollProgress: scrollProgress, onBack: close,
            content: { conversation(headerHeight: $0) }, trailing: { EmptyView() },
            footer: { composer },
            background: { backgroundImage }
        )
        .overlay { loadingIndicator }
        // Dibatalkan otomatis saat halaman hilang; tampil lagi = init ulang dan mengejar history.
        .task { await bridge.run() }
    }

    private func conversation(headerHeight: CGFloat) -> some View {
        ChatTable(
            state: tableState, headerHeight: headerHeight, actions: rowActions,
            onScrollProgress: { scrollProgress = $0 }, row: listRow
        )
    }

    /// Baris table tidak mewarisi environment halaman, jadi nilainya dipasang di sini. `id` mencegah state view
    /// terbawa saat sel dipakai ulang untuk pesan lain.
    private func listRow(_ item: ChatListItem, actions: ChatRowActions) -> some View {
        ChatListRow(item: item, welcome: welcome, content: content, actions: actions)
            .id(item.id)
            .designColors(colors)
            .environment(\.locale, locale)
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

// MARK: - Helpers

private extension ChatScreen {
    var isSendable: Bool { bridge.isReady && !bridge.isAwaitingReply }

    var rowActions: ChatRowActions {
        ChatRowActions(onOpenLink: onOpenLink, onSelectShortcut: select, onSelectFollowUp: selectFollowUp)
    }

    var tableState: ChatTableState {
        ChatTableState(
            items: listItems, sentQuestionID: bridge.latestSentQuestionID,
            incomingMessageID: bridge.latestIncomingMessageID, historyPhase: bridge.historyPhase,
            rowInputs: ChatRowInputs(welcome: welcome, locale: locale, colors: colors)
        )
    }

    var listItems: [ChatListItem] {
        var items = [ChatListItem](rows: bridge.rows)
        if welcome != nil, bridge.isWelcomeVisible {
            items.insert(.welcome(isEnabled: isEnabled && isSendable), at: .zero)
        }
        if !bridge.followUps.isEmpty {
            items.append(.followUps(bridge.followUps, isEnabled: isEnabled && isSendable))
        }
        if Content.self != EmptyView.self {
            items.append(.content)
        }
        return items
    }
}

// MARK: - Actions

private extension ChatScreen {
    func close() {
        if let onBack { onBack() } else { dismiss() }
    }

    /// True bila bubble pertanyaan tampil; false = ditolak dan draft tetap.
    func send(_ text: String) -> Bool {
        bridge.send(text) != nil
    }

    /// Menghentikan jawaban yang sedang berjalan; kunci dibuka oleh `turn_end` dari stream.
    func stop() {
        Task { [bridge] in await bridge.cancelTurn() }
    }

    /// Saran lanjutan dikirim sebagai chat, sama seperti shortcut.
    func selectFollowUp(_ question: String) {
        bridge.send(question)
    }

    /// Shortcut dikirim sebagai chat; bubble pertanyaan langsung tampil.
    func select(_ shortcut: WelcomeShortcut) {
        bridge.send(shortcut.prompt)
    }
}
