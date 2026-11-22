//
//  ChatScreen.swift
//  TanyaAI
//
//  Created by Wendra on 15/10/26.
//

import DesignKit
import SwiftUI

/// Halaman chat; draft composer dan koneksi gateway dimiliki pemiliknya masing-masing.
@MainActor
public struct ChatScreen<Content: View>: View {
    @Environment(\.locale) private var locale
    @Environment(\.dismiss) private var dismiss
    @Environment(\.designColors) private var colors
    @ObservedObject var bridge: TanyaAIBridge
    @State private var scrollProgress = CGFloat.zero
    @State private var isLatestVisible = true
    @State private var latestJumpID: UUID?
    @State var sheet: ChatSheet?
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
                attachmentSession: isAgentSession ? bridge.agentSessionKey : nil,
                leaveSession: isBannerVisible ? bridge.agentSessionKey : nil,
                isDismissable: !bridge.isSubmittingReferenceLetter,
                intentSheet: referenceLetterSheet,
                onPick: attach,
                onLeave: leave
            )
        )
        // Swipe-back milik navigasi host, jadi host yang menahannya selama sheet terbuka.
        .onChange(of: sheet != nil) { onSheetChange?($0) }
        .onChange(of: bridge.conversationID) { _ in
            if sheet?.referenceLetterMessageID != nil { sheet = nil }
        }
        .onDisappear {
            if sheet?.referenceLetterMessageID != nil { sheet = nil }
            onSheetChange?(false)
        }
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
            isReferenceLetterEnabled: bridge.services.referenceLetter != nil,
            onSheet: { if isEnabled && bridge.isReady { sheet = $0 } }
        )
        .id(item.id)
        .designColors(colors)
        .environment(\.locale, locale)
    }

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
    var isSendable: Bool { bridge.isReady && !bridge.isAwaitingReply }

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
        let notices = bridge.visibleLiveAgentNotices
        return ChatTableState(
            items: listItems(notices: notices), sentQuestionID: bridge.latestSentQuestionID,
            incomingMessageID: bridge.incomingContentID(latestNotice: notices.last), latestJumpID: latestJumpID,
            historyPhase: bridge.historyPhase,
            rowInputs: ChatRowInputs(welcome: welcome, locale: locale, colors: colors)
        )
    }

    func listItems(notices: [LiveAgentNotice]) -> [ChatListItem] {
        var items = [ChatListItem](rows: bridge.rows)
            .inserting(notices, isLeaveEnabled: isEnabled && !bridge.isLeavingAgent)
            .appendingAnswerLoading(isAwaitingReply: bridge.isAwaitingReply)
        if welcome != nil, bridge.isWelcomeVisible {
            items.insert(.welcome(isEnabled: isEnabled && isSendable), at: .zero)
        }
        if bridge.isAgentTyping {
            items.append(.agentTyping)
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
        guard let onBack else { return dismiss() }
        onBack()
    }

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

    func selectFollowUp(_ question: String) {
        bridge.send(question)
    }

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

    var attachAction: (() -> Void)? {
        guard isAgentSession else { return nil }
        return { sheet = .attachment(bridge.agentSessionKey, isFormatRejected: false) }
    }

    /// TODO: Upload dan preview setelah endpoint dan parameter stream tersedia pada gateway.
    func attach(_ file: URL) {
        FileManager.default.discardChatAttachment(at: file)
    }

    func select(_ shortcut: WelcomeShortcut) {
        bridge.send(shortcut.prompt)
    }
}
