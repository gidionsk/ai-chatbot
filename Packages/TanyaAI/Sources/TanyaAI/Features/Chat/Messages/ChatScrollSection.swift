//
//  ChatScrollSection.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

import DesignKit
import SwiftUI

/// Mengatur posisi scroll daftar pesan. Halaman dibuka di pesan terbaru. Pertanyaan baru parkir dekat atas dengan
/// preview jawaban sebelumnya; ruang kosong di bawahnya membuat itu tetap bisa walau jawaban masih pendek, dan
/// menyusut saat jawaban datang. Pesan di luar turn mengikuti ke bawah hanya bila posisi sudah dekat bawah,
/// jadi nasabah yang sedang membaca ke atas tidak terseret.
/// Closure `onChange` membaca nilai dari body sebelumnya, jadi nilai baru selalu lewat parameternya.
@MainActor
struct ChatScrollSection<Content: View>: View {
    @Environment(\.screenViewport) private var viewport
    @Environment(\.accessibilityReduceMotion) private var isReducingMotion
    /// Tinggi dari pertanyaan terbaru sampai ujung konten; nil sampai barisnya terukur.
    @State private var turnHeight: CGFloat?
    @State private var isParked = false
    @State private var isOpenedAtLatest = false
    private let sentQuestionID: String?
    private let incomingMessageID: String?
    private let historyPhase: ChatHistoryPhase
    private let content: Content

    init(
        sentQuestionID: String?, incomingMessageID: String?, historyPhase: ChatHistoryPhase,
        @ViewBuilder content: () -> Content
    ) {
        self.sentQuestionID = sentQuestionID
        self.incomingMessageID = incomingMessageID
        self.historyPhase = historyPhase
        self.content = content()
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: .zero) {
                measuredContent
                trailingSpace
            }
            .opacity(historyPhase == .restored && !isOpenedAtLatest ? .zero : CustomOpacity.opaque)
            .onAppear { open(historyPhase, proxy) }
            .onChange(of: historyPhase) { open($0, proxy) }
            .onChange(of: sentQuestionID) { park($0, proxy) }
            .onChange(of: incomingMessageID) { _ in followLatest(proxy) }
        }
    }

    private var measuredContent: some View {
        VStack(spacing: .zero) { content }
            .backgroundPreferenceValue(ChatQuestionTopKey.self) { top in
                GeometryReader { geometry in
                    let height = top.map { geometry.size.height - geometry[$0].y }
                    Color.clear
                        .onAppear { updateTurnHeight(height) }
                        .onChange(of: height, perform: updateTurnHeight)
                }
            }
    }

    private var trailingSpace: some View {
        Color.clear
            .frame(height: trailingSpaceHeight)
            .accessibilityHidden(true)
            .id(ChatElementIdentifier.latest)
    }
}

// MARK: - Helpers

private extension ChatScrollSection {
    /// Selama tinggi turn belum terukur, dipakai satu layar supaya pertanyaan pasti bisa mencapai posisi parkir.
    var trailingSpaceHeight: CGFloat {
        guard isParked else { return .zero }
        guard let turnHeight else { return viewport.height }
        return max(.zero, viewport.height - viewport.chatParkingOffset - turnHeight)
    }

    func updateTurnHeight(_ height: CGFloat?) {
        guard let height else { return }
        turnHeight = height
    }

    /// Penanda ditaruh ke tepi atas supaya posisi berhenti tepat di ujung konten, termasuk padding bawahnya.
    func scrollToLatest(_ proxy: ScrollViewProxy) {
        proxy.scrollTo(ChatElementIdentifier.latest, anchor: .top)
    }

    /// Konten disembunyikan sampai posisinya di bawah, supaya tidak terlihat melompat dari atas. Percakapan yang
    /// dimulai dari kosong dianggap sudah terbuka, jadi pesan pertamanya tidak memicu ini.
    func open(_ phase: ChatHistoryPhase, _ proxy: ScrollViewProxy) {
        guard phase != .loading, !isOpenedAtLatest else { return }
        guard phase == .restored else {
            isOpenedAtLatest = true
            return
        }
        DispatchQueue.main.async {
            scrollToLatest(proxy)
            isOpenedAtLatest = true
        }
    }

    func park(_ questionID: String?, _ proxy: ScrollViewProxy) {
        guard questionID != nil, viewport.height > .zero else { return }
        isParked = true
        turnHeight = nil
        let anchor = UnitPoint(x: UnitPoint.top.x, y: viewport.chatParkingOffset / viewport.height)
        DispatchQueue.main.async {
            animateScroll { proxy.scrollTo(ChatElementIdentifier.parking, anchor: anchor) }
        }
    }

    func followLatest(_ proxy: ScrollViewProxy) {
        guard isOpenedAtLatest, viewport.isNearBottom else { return }
        DispatchQueue.main.async {
            animateScroll { scrollToLatest(proxy) }
        }
    }

    /// Reduce Motion aktif = langsung pindah tanpa animasi.
    func animateScroll(_ scroll: () -> Void) {
        guard !isReducingMotion else {
            scroll()
            return
        }
        withAnimation(.easeOut, scroll)
    }
}
