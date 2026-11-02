//
//  ScreenHeaderTests.swift
//  DesignKit
//
//  Created by Wendra on 16/10/26.
//

import SwiftUI
import Testing

@testable import DesignKit

@MainActor
struct ScreenHeaderTests {
    @Test
    func longTitlesStayWithinCompactWidthsWithAndWithoutTrailingAction() throws {
        try FontFace.registerFonts()
        for width: CGFloat in [320, 375, 430] {
            for scrollProgress: CGFloat in [.zero, 0.5, 1] {
                for isNotched in [false, true] {
                    let title = String(repeating: "Judul panjang 中文 English ", count: 12)
                    let bare = ScreenHeader(
                        title: title, backLabel: "Back", scrollProgress: scrollProgress, isNotched: isNotched,
                        onBack: {}
                    )
                    let actions = ScreenHeader(
                        title: title, backLabel: "Back", scrollProgress: scrollProgress, isNotched: isNotched,
                        onBack: {},
                        trailing: { Button("More") {} }
                    )
                    expectBounds(bare, width: width, isNotched: isNotched)
                    expectBounds(actions, width: width, isNotched: isNotched)
                }
            }
        }
    }

    /// Sama dengan navigation bar host: padding atas 50 (notch) atau 28 dari tepi layar, tanpa scale.
    @Test
    func heightStartsAtTheScreenEdgeLikeTheHostNavigationBar() {
        let iconAndBottom = FigmaSize.weightIconSmall.scaledToArtwork + CustomSizes.Header.bottomPadding.scaledToArtwork
        #expect(ScreenHeader.height(isNotched: true) == CustomScreenInsets.headerTopWithNotch + iconAndBottom)
        #expect(ScreenHeader.height(isNotched: false) == CustomScreenInsets.headerTop + iconAndBottom)
    }

    @Test(arguments: [(CGFloat.zero, false), (20, false), (44, true), (47, true), (59, true)])
    func notchIsDetectedFromTheTopSafeArea(safeAreaTop: CGFloat, isNotched: Bool) {
        #expect(ScreenHeader.isNotched(safeAreaTop: safeAreaTop) == isNotched)
    }

    private func expectBounds(_ content: some View, width: CGFloat, isNotched: Bool) {
        let controller = UIHostingController(rootView: content)
        controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 800)
        controller.view.layoutIfNeeded()
        let size = controller.sizeThatFits(in: CGSize(width: width, height: 800))
        #expect(size.width <= width + 1)
        #expect(abs(size.height - ScreenHeader.height(isNotched: isNotched)) <= 1)
    }
}
