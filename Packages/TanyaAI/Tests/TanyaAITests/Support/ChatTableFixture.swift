//
//  ChatTableFixture.swift
//  TanyaAITests
//
//  Created by Wendra on 5/11/26.
//

import DesignKit
import SwiftUI
import UIKit

@testable import TanyaAI

/// `ChatTableController` pada window sungguhan, dengan baris berbeda tinggi seperti percakapan asli.
@MainActor
final class ChatTableFixture {
    typealias Cell = HostingTableViewCell<ChatTableFixtureRow>
    static let headerHeight: CGFloat = 100
    static let size = CGSize(width: 390, height: 700)
    let controller = ChatTableController()
    private let window = UIWindow(frame: CGRect(origin: .zero, size: ChatTableFixture.size))
    private var state = ChatTableState()

    var table: UITableView { controller.tableView }

    /// Window tanpa scene tidak menjalankan animasi, jadi scroll dibuat langsung kecuali `isReducingMotion` false.
    init(isReducingMotion: Bool = true, onBuild: @escaping () -> Void = {}) {
        controller.isReducingMotion = { isReducingMotion }
        window.rootViewController = controller
        window.isHidden = false
        controller.updateHeaderHeight(Self.headerHeight)
        controller.tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseIdentifier)
        controller.makeCell = { [weak controller] table, indexPath, item in
            let cell = table.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier, for: indexPath)
            guard let controller, let hostedCell = cell as? Cell else { return cell }
            onBuild()
            hostedCell.configure(rootView: ChatTableFixtureRow(item: item), parent: controller)
            return hostedCell
        }
        window.layoutIfNeeded()
    }

    func close() {
        window.isHidden = true
        window.rootViewController = nil
    }

    func update(
        items: [ChatListItem], phase: ChatHistoryPhase, sentQuestionID: String? = nil, incomingMessageID: String? = nil
    ) {
        state.items = items
        state.historyPhase = phase
        state.sentQuestionID = sentQuestionID ?? state.sentQuestionID
        state.incomingMessageID = incomingMessageID ?? state.incomingMessageID
        controller.update(state)
    }

    func spin(seconds: TimeInterval = 0.05) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    /// Pesan selang-seling; `m0` pertanyaan, `m1` jawaban, dan seterusnya.
    static func history(count: Int) -> [ChatListItem] {
        (0..<count).map { index in
            let author: ChatAuthor = index.isMultiple(of: 2) ? .user : .assistant
            let message = ChatMessage(
                id: "m\(index)", seq: index, author: author, text: "Pesan \(index)", status: .active
            )
            return .message(.message(message), isSpaced: index > 0)
        }
    }

    /// Jarak dari tepi atas table ke isi baris (setelah jarak antarbaris), pada posisi scroll saat ini.
    func contentTop(ofRow row: Int) -> CGFloat {
        table.rectForRow(at: IndexPath(row: row, section: .zero)).minY + state.items[row].topSpacing
            - table.contentOffset.y
    }

    func isRowVisible(_ row: Int) -> Bool {
        table.indexPathsForVisibleRows?.contains(IndexPath(row: row, section: .zero)) ?? false
    }
}

/// Tinggi berbeda-beda supaya perkiraan tinggi table tidak pernah kebetulan benar.
struct ChatTableFixtureRow: View {
    let item: ChatListItem

    var body: some View {
        Color.gray.frame(height: height)
    }

    private var height: CGFloat {
        guard case .message(let row, _) = item, let index = Int(row.id.dropFirst()) else { return 40 }
        return index.isMultiple(of: 2) ? 44 : CGFloat(200 + index % 7 * 40)
    }
}
