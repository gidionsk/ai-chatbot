//
//  HostingTableViewCellTests.swift
//  DesignKitTests
//
//  Created by Wendra on 5/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Jalur iOS 15 tidak punya runtime di mesin ini, jadi hosting controller-nya diuji langsung lewat `configureLegacy`.
@MainActor
struct HostingTableViewCellTests {
    private typealias Cell = HostingTableViewCell<Text>

    @Test
    func legacyContentJoinsTheParentAndLeavesWhenDetached() {
        let parent = UIViewController()
        let cell = Cell(style: .default, reuseIdentifier: Cell.reuseIdentifier)
        cell.configureLegacy(rootView: Text(verbatim: "Halo"), parent: parent)
        #expect(parent.children.count == 1)
        #expect(cell.contentView.subviews.count == 1)
        cell.detachHostedController()
        #expect(parent.children.isEmpty)
        #expect(cell.contentView.subviews.isEmpty)
    }

    /// Di iOS 15 hosting controller child memunculkan lagi navigation bar yang disembunyikan host.
    @Test
    func legacyContentCannotReachTheNavigationBarOfTheHost() throws {
        let parent = UIViewController()
        let navigation = UINavigationController(rootViewController: parent)
        let cell = Cell(style: .default, reuseIdentifier: Cell.reuseIdentifier)
        cell.configureLegacy(rootView: Text(verbatim: "Halo"), parent: parent)
        let controller = try #require(parent.children.first)
        #expect(parent.navigationController === navigation)
        #expect(controller.navigationController == nil)
    }

    @Test
    func legacyContentReusesItsControllerOnReconfigure() {
        let parent = UIViewController()
        let cell = Cell(style: .default, reuseIdentifier: Cell.reuseIdentifier)
        cell.configureLegacy(rootView: Text(verbatim: "Satu"), parent: parent)
        let controller = parent.children.first
        cell.configureLegacy(rootView: Text(verbatim: "Dua"), parent: parent)
        #expect(parent.children.count == 1)
        #expect(parent.children.first === controller)
    }

    @Test
    func reuseEmptiesTheLegacyContent() {
        let parent = UIViewController()
        let cell = Cell(style: .default, reuseIdentifier: Cell.reuseIdentifier)
        cell.configureLegacy(rootView: Text(verbatim: "Halo"), parent: parent)
        cell.prepareForReuse()
        #expect(parent.children.isEmpty)
    }

    /// Tinggi baris mengikuti konten saja: spacing desain tidak boleh bertambah oleh minimum bawaan sistem.
    @Test(arguments: [18, 24, 80] as [CGFloat], [false, true])
    func aRowIsAsTallAsItsContent(height: CGFloat, isLegacy: Bool) {
        let fixture = HostedRowFixture(contentHeight: height, isLegacy: isLegacy)
        defer { fixture.close() }
        #expect(abs(fixture.rowHeight - height) < 0.5)
    }

    /// Table menganggap tinggi 0 sebagai belum terukur dan memakai tinggi bawaan, jadi baris kosong menjadi jarak.
    @Test(arguments: [false, true])
    func anEmptyRowLeavesNoVisibleSpace(isLegacy: Bool) {
        let fixture = HostedRowFixture(contentHeight: .zero, isLegacy: isLegacy)
        defer { fixture.close() }
        #expect(fixture.rowHeight <= CustomSizes.HostedTable.minimumRowHeight.scaledToArtwork)
    }

    @Test
    func theReuseIdentifierDiffersPerContent() {
        #expect(HostingTableViewCell<Text>.reuseIdentifier != HostingTableViewCell<Image>.reuseIdentifier)
    }
}

/// Table sungguhan pada window, karena tinggi baris baru diputuskan saat table mengukur selnya.
@MainActor
private final class HostedRowFixture: NSObject, UITableViewDataSource {
    private typealias Cell = HostingTableViewCell<AnyView>
    private let contentHeight: CGFloat
    private let isLegacy: Bool
    private let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
    private let parent = UIViewController()
    private let table = UITableView(frame: .zero, style: .plain)

    init(contentHeight: CGFloat, isLegacy: Bool) {
        self.contentHeight = contentHeight
        self.isLegacy = isLegacy
        super.init()
        table.register(Cell.self, forCellReuseIdentifier: Cell.reuseIdentifier)
        table.dataSource = self
        table.separatorStyle = .none
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 100
        parent.view = table
        window.rootViewController = parent
        window.isHidden = false
        window.layoutIfNeeded()
    }

    var rowHeight: CGFloat {
        table.layoutIfNeeded()
        return table.rectForRow(at: IndexPath(row: .zero, section: .zero)).height
    }

    func close() {
        window.isHidden = true
        window.rootViewController = nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier, for: indexPath)
        let rootView = AnyView(Color.clear.frame(height: contentHeight))
        guard let hostedCell = cell as? Cell else { return cell }
        guard isLegacy else {
            hostedCell.configure(rootView: rootView, parent: parent)
            return cell
        }
        hostedCell.configureLegacy(rootView: rootView, parent: parent)
        return cell
    }
}
