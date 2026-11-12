//
//  ScrollBounceDisablerTests.swift
//  DesignKitTests
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Hanya scroll view yang berisi penanda yang berhenti memantul; scroll view lain di layar yang sama tidak berubah.
/// Berurutan karena memakai window.
@MainActor
@Suite(.serialized)
struct ScrollBounceDisablerTests {
    @Test
    func onlyTheScrollViewHoldingTheMarkerStopsBouncing() throws {
        let page = HStack(spacing: .zero) {
            ScrollView {
                Color.clear.frame(height: 2000).background(ScrollBounceDisabler())
            }
            ScrollView {
                Color.clear.frame(height: 2000)
            }
        }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = UIHostingController(rootView: page)
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        window.rootViewController?.view.layoutIfNeeded()
        let scrollViews = window.scrollViews.sorted { $0.frame.minX < $1.frame.minX }
        try #require(scrollViews.count == 2)
        #expect(!scrollViews[0].bounces)
        #expect(scrollViews[1].bounces)
    }
}

// MARK: - Helpers

private extension UIView {
    var scrollViews: [UIScrollView] {
        let own = (self as? UIScrollView).map { [$0] } ?? []
        return own + subviews.flatMap(\.scrollViews)
    }
}
