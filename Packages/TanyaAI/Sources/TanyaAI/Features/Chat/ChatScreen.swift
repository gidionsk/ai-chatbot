//
//  ChatScreen.swift
//  TanyaAI
//
//  Created by Wendra on 15/10/26.
//

import DesignKit
import SwiftUI

/// Halaman chat: fitur ini memiliki header-nya sendiri, draft hidup di `ComposerSection`, dan `content` disisipkan
/// pemakai.
/// `welcome` (dari BE) hanya tampil bila history kosong; sebelum history pertama selesai, loading di tengah.
/// Shortcut yang diketuk dikirim lewat `bridge` seperti chat.
/// Selama halaman tampil, `bridge` tersambung ke gateway. Setelah kirim, bubble pertanyaan langsung tampil dan
/// tombol menjadi stop sampai jawaban selesai; shortcut nonaktif selama menunggu.
@MainActor
public struct ChatScreen<Content: View>: View {
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    @Environment(\.designColors) private var colors
    @ObservedObject private var bridge: TanyaAIBridge
    @State private var scrollProgress = CGFloat.zero
    @State private var isLatestVisible = true
    @State private var latestJumpID: UUID?
    /// Bottom sheet yang sedang tampil; nil = tertutup.
    @State private var sheet: ChatSheet?
    private let isEnabled: Bool
    private let welcome: WelcomeContent?
    private let onBack: (() -> Void)?
    private let onOpenLink: (String) -> Void
    private let onSheetChange: ((Bool) -> Void)?
    private let content: Content

    public init(
        isEnabled: Bool = true, welcome: WelcomeContent? = nil, bridge: TanyaAIBridge,
        onBack: (() -> Void)? = nil, onOpenLink: @escaping (String) -> Void = { _ in },
        onSheetChange: ((Bool) -> Void)? = nil, @ViewBuilder content: () -> Content
    ) {
        _bridge = ObservedObject(wrappedValue: bridge)
        self.isEnabled = isEnabled
        self.welcome = welcome
        self.onBack = onBack
        self.onOpenLink = onOpenLink
        self.onSheetChange = onSheetChange
        self.content = content()
    }

    public var body: some View {
        ScreenScaffold(
            title: String(ChatCopy.title, locale: locale),
            backLabel: String(ChatCopy.back, locale: locale),
            // Selama bar sesi agen tampil daftar mulai di bawah bar, jadi efek scroll header tidak dipakai.
            scrollProgress: isBannerVisible ? .zero : scrollProgress, onBack: close,
            content: { conversation(headerHeight: $0) }, trailing: { EmptyView() },
            footer: { composer },
            background: { ChatBackground() }
        )
        .overlay { loadingIndicator }
        .modifier(
            ChatSheetModifier(
                sheet: $sheet,
                bridge: bridge,
                attachmentSession: isAgentSession ? bridge.agentSessionKey : nil,
                leaveSession: isBannerVisible ? bridge.agentSessionKey : nil,
                onPick: attach,
                onLeave: leave
            )
        )
        // Swipe-back milik navigasi host, jadi host yang menahannya selama sheet terbuka.
        .onChange(of: sheet != nil) { onSheetChange?($0) }
        // Dibatalkan otomatis saat halaman hilang; tampil lagi = init ulang dan mengejar history.
        .task { await bridge.run() }
    }

    /// Bar sesi agen menempel di bawah header, jadi daftar mulai di bawah bar tanpa inset header.
    private func conversation(headerHeight: CGFloat) -> some View {
        VStack(spacing: .zero) {
            agentSessionBanner(headerHeight: headerHeight)
            ChatTable(
                state: tableState, headerHeight: isBannerVisible ? .zero : headerHeight, actions: rowActions,
                onScrollProgress: { scrollProgress = $0 }, onLatestVisibilityChange: { isLatestVisible = $0 },
                row: listRow
            )
            .overlay(alignment: .bottom) { latestButton }
        }
    }

    @ViewBuilder
    private func agentSessionBanner(headerHeight: CGFloat) -> some View {
        if isBannerVisible {
            // End Session dikonfirmasi dulu di bottom sheet.
            AgentSessionBanner(onEnd: { sheet = .leaveAgent(bridge.agentSessionKey) })
                .disabled(!isEnabled || bridge.isLeavingAgent)
                .padding(.top, headerHeight)
        }
    }

    /// Mengambang di tengah, tepat di atas composer, selama ujung daftar di luar layar.
    /// TODO: Konfirmasi jarak ke composer dengan Figma; sementara perkiraan dari foto.
    @ViewBuilder
    private var latestButton: some View {
        if !isLatestVisible {
            FloatingIconButton(icon: .arrowDown, onTap: showLatest)
                .accessibilityLabel(String(ChatCopy.scrollToLatest, locale: locale))
                .padding(.bottom, FigmaSize.spacingLarge.scaledToArtwork)
                .accessibilityIdentifier(ChatElementIdentifier.scrollToLatest)
        }
    }

    /// Baris table tidak mewarisi environment halaman, jadi nilainya dipasang di sini. `id` mencegah state view
    /// terbawa saat sel dipakai ulang untuk pesan lain.
    private func listRow(_ item: ChatListItem, actions: ChatRowActions) -> some View {
        ChatListRow(
            item: item,
            welcome: welcome,
            content: content,
            actions: actions,
            referenceLetter: bridge.referenceLetter(for: item),
            isReferenceLetterEnabled: bridge.isReferenceLetterEnabled(for: item),
            onSheet: { candidate in
                guard isEnabled, bridge.isReady else { return }
                sheet = candidate.afterReferenceLetterCompletion(in: bridge.messages)
            }
        )
        .id(item.id)
        .designColors(colors)
        .environment(\.locale, locale)
    }

    /// Hanya saat pertama dibuka; menyambung ulang tidak menutupi pesan yang sudah tampil. Gagal permanen
    /// menghentikan loading; error ditampilkan host lewat `onConnectionFailed`/`onSessionExpired`.
    @ViewBuilder
    private var loadingIndicator: some View {
        if bridge.isLoadingHistory {
            LoadingIndicator()
                .accessibilityIdentifier(ChatElementIdentifier.loading)
        }
    }

    private var composer: some View {
        ComposerSection(
            isEnabled: isEnabled && bridge.isReady,
            isInputEnabled: !bridge.isSwitchingToAgent,
            phase: bridge.turnPhase,
            onSend: send,
            onStop: stop,
            onAttach: attachAction,
            onTyping: typingChanged
        )
    }
}

// MARK: - Helpers

private extension ChatScreen {
    var isBannerVisible: Bool { bridge.isAgentSessionBannerVisible }

    /// Lampiran hanya selama `AGENT_ACTIVE`; bar sesi agen sudah tampil sejak sapaan otomatis selama antre.
    var isAgentSession: Bool { bridge.conversationState == .agentActive }

    var rowActions: ChatRowActions {
        ChatRowActions(
            onOpenLink: onOpenLink, onSelectShortcut: select, onSelectFollowUp: selectFollowUp,
            onLeaveAgentQueue: leaveAgent
        )
    }

    var tableState: ChatTableState {
        ChatTableState(
            items: bridge.listItems(
                isEnabled: isEnabled,
                isWelcomeAvailable: welcome != nil,
                isContentInjected: Content.self != EmptyView.self
            ),
            sentQuestionID: bridge.latestSentQuestionID,
            incomingMessageID: bridge.incomingContentID(latestNotice: bridge.visibleLiveAgentNotices.last),
            latestJumpID: latestJumpID,
            historyPhase: bridge.historyPhase,
            rowInputs: ChatRowInputs(welcome: welcome, locale: locale, colors: colors),
            referenceLetterLayouts: bridge.referenceLetterLayouts
        )
    }
}

// MARK: - Actions

private extension ChatScreen {
    func close() {
        guard let onBack else { return dismiss() }
        onBack()
    }

    /// True bila bubble pertanyaan tampil; false = ditolak dan draft tetap.
    func send(_ text: String) -> Bool {
        bridge.send(text) != nil
    }

    /// Menghentikan jawaban yang sedang berjalan; kunci dibuka oleh `turn_end` dari stream.
    func stop() {
        Task { [bridge] in await bridge.cancelTurn() }
    }

    /// Tombol panah: kembali ke pesan terbaru yang sebenarnya, juga saat pertanyaan sedang parkir.
    func showLatest() {
        latestJumpID = UUID()
    }

    /// Saran lanjutan dikirim sebagai chat, sama seperti shortcut.
    func selectFollowUp(_ question: String) {
        bridge.send(question)
    }

    /// Draft composer berisi atau kosong; diteruskan ke agen sebagai sinyal mengetik.
    func typingChanged(_ isTyping: Bool) {
        bridge.userTypingChanged(isTyping)
    }

    /// "Batalkan" di dalam kartu antre: antrean yang tampil saat diketuk.
    func leaveAgent() {
        leave(bridge.agentSessionKey)
    }

    /// Batalkan atau Yes di konfirmasi End Session; bridge mengecek ulang `session` tepat sebelum request.
    func leave(_ session: AgentSessionKey) {
        Task { [bridge] in await bridge.leaveAgent(from: session) }
    }

    /// Lampiran (PDF/gambar) hanya saat dilayani agen; nil = tombol tidak tampil. Ketuk = bottom sheet Galeri / File.
    var attachAction: (() -> Void)? {
        guard isAgentSession else { return nil }
        return { sheet = .attachment(bridge.agentSessionKey, isFormatRejected: false) }
    }

    /// File pilihan nasabah. Salinannya langsung dibuang supaya tidak menumpuk di folder sementara.
    /// TODO: Upload lewat transport dan kartu preview setelah endpoint upload dan parameter stream ada di contract
    /// gateway; saat itu file dibuang oleh pemilik upload setelah selesai (atau bila agen sudah tidak melayani).
    func attach(_ file: URL) {
        FileManager.default.discardChatAttachment(at: file)
    }

    /// Shortcut dikirim sebagai chat; bubble pertanyaan langsung tampil.
    func select(_ shortcut: WelcomeShortcut) {
        bridge.send(shortcut.prompt)
    }
}
