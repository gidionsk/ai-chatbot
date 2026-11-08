//
//  ChatTableController+Scroll.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

import DesignKit
import UIKit

extension ChatTableController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        guard state.items.indices.contains(indexPath.row) else { return tableView.estimatedRowHeight }
        return measuredHeights[state.items[indexPath.row].id] ?? tableView.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as? HostedContentAttaching)?.attachHostedController(to: self)
        recordHeight(of: cell, at: indexPath)
    }

    func tableView(_ table: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        (cell as? HostedContentAttaching)?.detachHostedController()
    }

    /// Baris yang sudah tampil bisa berubah tinggi saat isinya di-reconfigure.
    func recordVisibleHeights() {
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            guard let cell = tableView.cellForRow(at: indexPath) else { continue }
            recordHeight(of: cell, at: indexPath)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isUserScrolling { recordReadingPosition() }
        refreshNearBottom()
        reportScrollProgress()
    }

    /// Menggeser membatalkan parkir: posisi kini milik nasabah.
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isHoldingParking = false
        isScrollAnimating = false
        isFollowingLatest = false
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isScrollAnimating = false
        guard isFollowingLatest else {
            maintainParking()
            recordSettledPosition()
            return
        }
        continueFollowingLatest()
        recordSettledPosition()
    }

    /// Posisi terprogram pasti setelah layout, dan selama animasi berjalan belum ada posisi akhirnya.
    func recordSettledPosition() {
        guard !isScrollAnimating else { return }
        tableView.layoutIfNeeded()
        recordReadingPosition()
    }

    /// Direkam hanya saat posisi sudah pasti: scroll terprogram yang belum ter-layout masih melaporkan baris lama.
    func recordReadingPosition() {
        guard let indexPath = tableView.indexPathsForVisibleRows?.first,
            state.items.indices.contains(indexPath.row)
        else { return }
        anchorItemID = state.items[indexPath.row].id
        anchorDistance = tableView.rectForRow(at: indexPath).minY - tableView.contentOffset.y
    }

    /// Tinggi baris di atas layar bisa berubah tanpa scroll, mis. saat VoiceOver membaca daftar dan baris yang belum
    /// tampil ikut terukur. Table tidak mengoreksi itu sendiri, jadi posisi dijaga lewat baris, bukan angka offset.
    func restoreReadingPosition() {
        guard !isUserScrolling, !isScrollAnimating, !isHoldingParking, let anchorItemID,
            let row = state.items.firstIndex(where: { $0.id == anchorItemID })
        else { return }
        let rowTop = tableView.rectForRow(at: IndexPath(row: row, section: .zero)).minY
        scroll(to: rowTop - anchorDistance, isAnimated: false)
    }

    /// Scroll bisa terjadi di tengah update SwiftUI, jadi nilainya dikirim pada putaran berikutnya.
    func reportScrollProgress() {
        let offset = tableView.contentOffset.y + tableView.adjustedContentInset.top
        let progress = CGFloat.scrollProgress(offset: offset, distance: headerHeight)
        guard progress != latestProgress else { return }
        latestProgress = progress
        guard !isProgressPending else { return }
        isProgressPending = true
        DispatchQueue.main.async { [weak self] in self?.publishScrollProgress() }
    }

    private func recordHeight(of cell: UITableViewCell, at indexPath: IndexPath) {
        guard state.items.indices.contains(indexPath.row) else { return }
        measuredHeights[state.items[indexPath.row].id] = cell.bounds.height
    }

    private func publishScrollProgress() {
        isProgressPending = false
        onScrollProgress(latestProgress)
    }
}
