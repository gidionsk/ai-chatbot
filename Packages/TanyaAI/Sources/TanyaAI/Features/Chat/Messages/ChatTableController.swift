//
//  ChatTableController.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

import DesignKit
import UIKit

/// Pemilik table percakapan dan posisi scroll-nya. `UIViewController` biasa, bukan `UITableViewController`, supaya
/// keyboard dan safe area hanya diatur SwiftUI; baris hosting iOS 15 butuh controller ini sebagai parent.
final class ChatTableController: UIViewController {
    let tableView = LayoutTrackingTableView(frame: .zero, style: .plain)
    var onScrollProgress: (CGFloat) -> Void = { _ in }
    var makeCell: ((UITableView, IndexPath, ChatListItem) -> UITableViewCell)?
    /// Bisa diganti di test; default mengikuti pengaturan Reduce Motion.
    var isReducingMotion: () -> Bool = { UIAccessibility.isReduceMotionEnabled }
    /// Bisa berubah setelah render pertama: safe area baru terbaca setelah halaman terpasang.
    var headerHeight = CGFloat.zero
    var state = ChatTableState()
    /// Ruang kosong di bawah konten supaya pertanyaan bisa parkir walau jawabannya masih pendek.
    var trailingInset = CGFloat.zero
    /// True sejak pertanyaan parkir: ruang kosong di bawah terus mengikuti tinggi jawaban.
    var isParked = false
    /// True sampai nasabah menggeser: posisi pertanyaan dijaga walau layout berubah.
    var isHoldingParking = false
    var isScrollAnimating = false
    /// True selama animasi menuju pesan terbaru belum sampai ke ujung yang sudah terukur.
    var isFollowingLatest = false
    var isOpened = false
    var isNearBottom = true
    var isStickingToBottom = false
    var isAdjustmentPending = false
    var isProgressPending = false
    var latestProgress = CGFloat.zero
    var trackedHeight = CGFloat.zero
    /// Tinggi terukur per baris. Tanpa ini table memperkirakan ulang baris di luar layar, sehingga posisi scroll
    /// bergeser ke baris lain.
    var measuredHeights: [ChatListItemID: CGFloat] = [:]
    /// Baris teratas yang tampil dan jaraknya dari posisi scroll, untuk menjaga posisi baca.
    var anchorItemID: ChatListItemID?
    var anchorDistance = CGFloat.zero
    private var dataSource: UITableViewDiffableDataSource<Int, ChatListItemID>?

    override func loadView() {
        view = tableView
        configureTable()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        moveHeaderInset { applyInsets() }
    }

    func updateHeaderHeight(_ height: CGFloat) {
        loadViewIfNeeded()
        guard headerHeight != height else { return }
        moveHeaderInset {
            headerHeight = height
            applyInsets()
        }
    }

    /// Item dan pemicu diterapkan dalam satu update, jadi layar tidak pernah menggambar posisi lama dengan isi baru.
    func update(_ newState: ChatTableState) {
        loadViewIfNeeded()
        guard newState != state else { return }
        let previous = state
        let isReaderAtBottom = isNearBottom
        state = newState
        applyItems(replacing: previous.items)
        openIfNeeded()
        restoreReadingPosition()
        moveToNewContent(after: previous, isReaderAtBottom: isReaderAtBottom)
        maintainParking()
        refreshNearBottom()
    }
}

// MARK: - Helpers

private extension ChatTableController {
    func configureTable() {
        let dataSource = UITableViewDiffableDataSource<Int, ChatListItemID>(
            tableView: tableView,
            cellProvider: { [weak self] table, indexPath, _ in self?.cell(in: table, at: indexPath) }
        )
        dataSource.defaultRowAnimation = .none
        self.dataSource = dataSource
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = CustomSizes.HostedTable.estimatedRowHeight.scaledToArtwork
        // Table membentang sampai tepi atas layar di belakang header. Dengan `.never`, safe area diteruskan ke sel dan
        // menambah tinggi baris yang melintas di bawah status bar, jadi daftar bergeser sendiri.
        tableView.contentInsetAdjustmentBehavior = .always
        tableView.accessibilityIdentifier = ChatElementIdentifier.messages
        applyInsets()
        tableView.contentOffset.y = -tableView.adjustedContentInset.top
        tableView.onLayoutChange = { [weak self] in self?.tableLayoutDidChange() }
    }

    func cell(in table: UITableView, at indexPath: IndexPath) -> UITableViewCell? {
        guard state.items.indices.contains(indexPath.row), let makeCell else { return UITableViewCell() }
        return makeCell(table, indexPath, state.items[indexPath.row])
    }

    /// Baris yang sama dengan isi berubah di-reconfigure di tempat, supaya sel dan posisi scroll tetap.
    func applyItems(replacing previous: [ChatListItem]) {
        guard state.items != previous else { return }
        let previousByID = Dictionary(previous.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var snapshot = NSDiffableDataSourceSnapshot<Int, ChatListItemID>()
        snapshot.appendSections([.zero])
        snapshot.appendItems(state.items.map(\.id))
        snapshot.reconfigureItems(
            state.items.filter { item in previousByID[item.id].map { $0 != item } ?? false }.map(\.id)
        )
        // Tanpa animasi, snapshot diterapkan seperti `reloadData` dan semua tinggi terukur hilang. Batch update di
        // dalam `performWithoutAnimation` mempertahankannya tanpa animasi baris.
        UIView.performWithoutAnimation {
            dataSource?.apply(snapshot, animatingDifferences: true)
            // Posisi dihitung sesudah ini; sebelum layout, baris yang diganti masih memakai perkiraan tinggi.
            tableView.layoutIfNeeded()
        }
    }

    /// Posisi teratas ikut pindah, supaya konten tidak tertutup header setelah insetnya berubah.
    func moveHeaderInset(_ change: () -> Void) {
        let topOffset = -tableView.adjustedContentInset.top
        let isAtTop = abs(tableView.contentOffset.y - topOffset) <= LayoutTolerance.measurement
        change()
        guard isAtTop else { return }
        tableView.contentOffset.y = -tableView.adjustedContentInset.top
    }

    func moveToNewContent(after previous: ChatTableState, isReaderAtBottom: Bool) {
        if state.sentQuestionID != nil, state.sentQuestionID != previous.sentQuestionID {
            parkLatestQuestion()
            return
        }
        if state.incomingMessageID != previous.incomingMessageID, isReaderAtBottom {
            followLatest()
        }
    }

    func tableLayoutDidChange() {
        let isHeightChanged = trackedHeight != tableView.bounds.height
        trackedHeight = tableView.bounds.height
        // Keyboard mengecilkan table: nasabah yang di ujung daftar tetap melihat pesan terakhir.
        isStickingToBottom = isStickingToBottom || (isHeightChanged && isNearBottom && isOpened)
        scheduleLayoutAdjustment()
    }

    /// Laporan layout datang di tengah layout, dan bisa beruntun, jadi digabung ke satu putaran berikutnya.
    func scheduleLayoutAdjustment() {
        guard !isAdjustmentPending else { return }
        isAdjustmentPending = true
        DispatchQueue.main.async { [weak self] in self?.adjustAfterLayout() }
    }

    func adjustAfterLayout() {
        isAdjustmentPending = false
        recordVisibleHeights()
        openIfNeeded()
        stickToBottomIfNeeded()
        restoreReadingPosition()
        maintainParking()
        recordSettledPosition()
        refreshNearBottom()
        reportScrollProgress()
    }
}
