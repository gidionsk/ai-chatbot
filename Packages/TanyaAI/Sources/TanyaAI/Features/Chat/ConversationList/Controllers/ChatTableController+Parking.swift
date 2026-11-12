//
//  ChatTableController+Parking.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

import DesignKit
import UIKit

/// Aturan posisi: halaman dibuka di pesan terbaru. Pertanyaan baru parkir dekat atas dengan preview jawaban sebelumnya;
/// ruang kosong di bawahnya membuat itu tetap bisa walau jawaban masih pendek, dan menyusut saat jawaban datang.
/// Pesan di luar turn mengikuti ke bawah hanya bila posisi sudah dekat bawah, jadi nasabah yang membaca ke atas tidak
/// terseret.
extension ChatTableController {
    var isUserScrolling: Bool { tableView.isDragging || tableView.isDecelerating }
    /// Ujung daftar terlihat, atau sedang dituju animasi ke pesan terbaru. Ini yang dilaporkan ke halaman: selama
    /// daftar sendiri sedang menuju ujung, tombol ke pesan terbaru tidak perlu muncul.
    var isLatestInReach: Bool { isNearBottom || scrollMode == .followingLatest }

    var baseBottomInset: CGFloat { FigmaSize.spacingLarge.scaledToArtwork }

    /// Jarak tepi atas table ke pertanyaan yang parkir: di bawah header, menyisakan preview jawaban sebelumnya.
    var parkingOffset: CGFloat { headerHeight + FigmaSize.spacingDoubleExtraLarge.scaledToArtwork }

    /// Posisi saat ujung konten tepat di bawah, tanpa ruang kosong parkir. Negatif bila konten lebih pendek dari layar.
    var contentEndOffset: CGFloat { tableView.contentSize.height - tableView.bounds.height + baseBottomInset }

    /// Posisi terbawah yang bisa dicapai tanpa ruang kosong parkir.
    var bottomOffset: CGFloat { max(-tableView.adjustedContentInset.top, contentEndOffset) }

    /// `adjustedContentInset` menambahkan safe area ke `contentInset`, jadi bagian atasnya dikurangi lagi.
    func applyInsets() {
        let insets = UIEdgeInsets(
            top: headerHeight + FigmaSize.spacingLarge.scaledToArtwork - tableView.safeAreaInsets.top, left: .zero,
            bottom: baseBottomInset + trailingInset, right: .zero
        )
        guard tableView.contentInset != insets else { return }
        tableView.contentInset = insets
    }

    /// Percakapan yang dimulai dari kosong dianggap sudah terbuka, jadi pesan pertamanya tidak memicu ini.
    func openIfNeeded() {
        guard !isOpened, state.historyPhase != .loading, tableView.bounds.height > .zero else { return }
        isOpened = true
        guard state.historyPhase == .restored else { return }
        settleAtBottom()
        recordSettledPosition()
        refreshNearBottom()
    }

    func parkLatestQuestion() {
        scrollMode = .holdingQuestion
        tableView.layoutIfNeeded()
        refreshTrailingInset()
        guard let target = parkingTarget else { return }
        scroll(to: target, isAnimated: true)
    }

    /// Pesan yang datang selagi animasi sebelumnya belum selesai (beruntun, mis. stream mengulang satu sesi agen saat
    /// halaman dibuka) langsung ditaruh di ujung. Kalau tiap pesan memulai animasi baru, daftar bergerak tersendat
    /// lama setelah pesan terakhir tiba.
    func followLatest() {
        guard isOpened else { return }
        let isCatchingUp = scrollMode == .followingLatest
        scrollMode = .free
        setTrailingInset(.zero)
        tableView.layoutIfNeeded()
        scroll(to: bottomOffset, isAnimated: !isCatchingUp)
        scrollMode = isScrollAnimating ? .followingLatest : .free
        guard scrollMode == .free else { return }
        settleAtBottom()
        recordSettledPosition()
    }

    /// Baris baru masih memakai perkiraan tinggi saat dibidik, jadi setelah terukur sisa jaraknya digeser lagi.
    func continueFollowingLatest() {
        scroll(to: bottomOffset, isAnimated: true)
        scrollMode = isScrollAnimating ? .followingLatest : .free
    }

    /// Ruang kosong selalu diperbarui; posisi hanya dikoreksi selama parkir dijaga dan tidak ada animasi berjalan.
    func maintainParking() {
        guard scrollMode.isQuestionParked else { return }
        refreshTrailingInset()
        guard !isScrollAnimating else { return }
        guard scrollMode == .holdingQuestion, let target = parkingTarget else {
            clampToContentEnd()
            return
        }
        scroll(to: target, isAnimated: false)
    }

    /// Nasabah di ujung daftar tetap di ujung saat tinggi table berubah. Acuan posisi baca hanya untuk yang lain: kalau
    /// ikut dijalankan, daftar kembali ke posisi lama dan pesan terakhir tertutup keyboard.
    func keepPositionAfterLayout() {
        defer { isStickingToBottom = false }
        guard isStickingToBottom, scrollMode != .holdingQuestion, !isUserScrolling else {
            restoreReadingPosition()
            return
        }
        scroll(to: bottomOffset + trailingInset, isAnimated: false)
    }

    func scroll(to offset: CGFloat, isAnimated: Bool) {
        isScrollAnimating = false
        guard abs(tableView.contentOffset.y - offset) > LayoutTolerance.measurement else { return }
        isScrollAnimating = isAnimated && !isReducingMotion()
        tableView.setContentOffset(CGPoint(x: tableView.contentOffset.x, y: offset), animated: isScrollAnimating)
    }

    func refreshNearBottom() {
        let visibleBottom = tableView.contentOffset.y + tableView.bounds.height
        let contentEnd = tableView.contentSize.height + baseBottomInset
        isNearBottom = contentEnd - visibleBottom <= FigmaSize.spacingDoubleExtraLarge.scaledToArtwork
        reportLatestVisibility()
    }
}

// MARK: - Helpers

private extension ChatTableController {
    /// Tepi atas isi pertanyaan terbaru pada posisi parkir, tidak melewati posisi teratas.
    var parkingTarget: CGFloat? {
        guard let index = state.items.lastIndex(where: \.isQuestion) else { return nil }
        let rowTop = tableView.rectForRow(at: IndexPath(row: index, section: .zero)).minY
        return max(-tableView.adjustedContentInset.top, rowTop + state.items[index].topSpacing - parkingOffset)
    }

    func refreshTrailingInset() {
        guard let target = parkingTarget else { return }
        setTrailingInset(max(.zero, target - contentEndOffset))
    }

    func setTrailingInset(_ inset: CGFloat) {
        guard abs(trailingInset - inset) > LayoutTolerance.measurement else { return }
        trailingInset = inset
        applyInsets()
    }

    /// Ruang kosong bisa menyusut saat posisi ada di dalamnya; table tidak mengoreksi itu sendiri.
    func clampToContentEnd() {
        let contentEnd = bottomOffset + trailingInset
        guard !isUserScrolling, tableView.contentOffset.y > contentEnd else { return }
        scroll(to: contentEnd, isAnimated: false)
    }

    /// `contentSize` masih memakai perkiraan tinggi untuk baris yang belum terukur, jadi yang dibidik baris terakhir,
    /// bukan ujung `contentSize`. Diulang sampai stabil dalam putaran yang sama, supaya frame pertama yang tampil
    /// sudah di pesan terbaru tanpa lompatan dari atas.
    func settleAtBottom() {
        guard !state.items.isEmpty else { return }
        let lastRow = IndexPath(row: state.items.index(before: state.items.endIndex), section: .zero)
        var previousHeight: CGFloat?
        for _ in .zero..<LayoutTolerance.settlingPasses where tableView.contentSize.height != previousHeight {
            previousHeight = tableView.contentSize.height
            tableView.scrollToRow(at: lastRow, at: .bottom, animated: false)
            tableView.layoutIfNeeded()
        }
    }
}
