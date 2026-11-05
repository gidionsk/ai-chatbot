//
//  ChatTable.swift
//  TanyaAI
//
//  Created by Wendra on 5/11/26.
//

import DesignKit
import SwiftUI
import UIKit

/// Table percakapan dengan baris SwiftUI. Baris di-recycle, jadi biaya layout tidak naik mengikuti panjang sesi.
@MainActor
struct ChatTable<Row: View>: UIViewControllerRepresentable {
    private typealias HostedCell = HostingTableViewCell<Row>
    private let state: ChatTableState
    private let headerHeight: CGFloat
    private let onScrollProgress: (CGFloat) -> Void
    private let row: (ChatListItem) -> Row

    init(
        state: ChatTableState, headerHeight: CGFloat, onScrollProgress: @escaping (CGFloat) -> Void,
        @ViewBuilder row: @escaping (ChatListItem) -> Row
    ) {
        self.state = state
        self.headerHeight = headerHeight
        self.onScrollProgress = onScrollProgress
        self.row = row
    }

    func makeUIViewController(context: Context) -> ChatTableController {
        let controller = ChatTableController()
        controller.tableView.register(HostedCell.self, forCellReuseIdentifier: HostedCell.reuseIdentifier)
        return controller
    }

    /// Penyedia sel selalu dipasang ulang: closure `row` membawa nilai terbaru dari `ChatScreen`.
    func updateUIViewController(_ controller: ChatTableController, context: Context) {
        controller.onScrollProgress = onScrollProgress
        controller.updateHeaderHeight(headerHeight)
        controller.makeCell = { [row, weak controller] table, indexPath, item in
            let cell = table.dequeueReusableCell(withIdentifier: HostedCell.reuseIdentifier, for: indexPath)
            guard let controller, let hostedCell = cell as? HostedCell else { return cell }
            hostedCell.configure(rootView: row(item), parent: controller)
            return hostedCell
        }
        controller.update(state)
    }
}
