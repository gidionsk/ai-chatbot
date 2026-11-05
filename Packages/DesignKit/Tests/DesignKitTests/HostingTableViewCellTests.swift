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

    @Test
    func theReuseIdentifierDiffersPerContent() {
        #expect(HostingTableViewCell<Text>.reuseIdentifier != HostingTableViewCell<Image>.reuseIdentifier)
    }
}
