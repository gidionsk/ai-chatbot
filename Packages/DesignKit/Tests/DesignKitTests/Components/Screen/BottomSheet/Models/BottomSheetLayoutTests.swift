//
//  BottomSheetLayoutTests.swift
//  DesignKitTests
//
//  Created by Wendra on 14/11/26.
//

import CoreGraphics
import Testing

@testable import DesignKit

/// Batas tinggi dan letak sheet: di bawah status bar, lebih rendah lagi di layar tanpa notch, dan di atas keyboard.
struct BottomSheetLayoutTests {
    private let classicTopGap = CustomSizes.BottomSheet.classicTopGap.scaledToArtwork
    private let screenHeight: CGFloat = 812
    private let notchTop: CGFloat = 47
    private let homeIndicator: CGFloat = 34

    @Test
    func aNotchedScreenStopsRightBelowTheStatusBar() {
        let layout = notched()
        #expect(layout.sheetMaxHeight == screenHeight - notchTop)
        #expect(layout.bottomInset == homeIndicator)
        #expect(layout.keyboardHeight == .zero)
    }

    @Test(arguments: [CGFloat.zero, 20])
    func aClassicScreenLeavesAGapBelowTheStatusBar(safeAreaTop: CGFloat) {
        let layout = BottomSheetLayout(
            screenHeight: screenHeight,
            safeAreaTop: safeAreaTop,
            safeAreaBottom: .zero,
            keyboardTop: nil,
            maxHeight: .belowStatusBar
        )
        #expect(layout.sheetMaxHeight == screenHeight - safeAreaTop - classicTopGap)
    }

    @Test
    func aKeyboardLiftsTheSheetAndCoversTheHomeIndicator() {
        let keyboardTop: CGFloat = 476
        let layout = notched(keyboardTop: keyboardTop)
        #expect(layout.keyboardHeight == screenHeight - keyboardTop)
        #expect(layout.bottomInset == .zero)
        #expect(layout.sheetMaxHeight == keyboardTop - notchTop)
    }

    /// Notifikasi keyboard menutup membawa tepi atas di tepi bawah layar (atau lebih rendah).
    @Test(arguments: [CGFloat(812), 900])
    func aClosedKeyboardChangesNothing(keyboardTop: CGFloat) {
        let layout = notched(keyboardTop: keyboardTop)
        #expect(layout.keyboardHeight == .zero)
        #expect(layout.bottomInset == homeIndicator)
        #expect(layout.sheetMaxHeight == screenHeight - notchTop)
    }

    @Test
    func aFractionIsCutByTheKeyboardOnlyWhenItNoLongerFits() {
        let tightTop: CGFloat = 400
        let roomy = notched(keyboardTop: 700, maxHeight: .screenFraction(0.5))
        let tight = notched(keyboardTop: tightTop, maxHeight: .screenFraction(0.5))
        #expect(roomy.sheetMaxHeight == screenHeight / 2)
        #expect(tight.sheetMaxHeight == tightTop - notchTop)
    }
}

// MARK: - Helpers

private extension BottomSheetLayoutTests {
    /// Layar 812 dengan notch dan home indicator.
    func notched(keyboardTop: CGFloat? = nil, maxHeight: BottomSheetMaxHeight = .belowStatusBar) -> BottomSheetLayout {
        BottomSheetLayout(
            screenHeight: screenHeight,
            safeAreaTop: notchTop,
            safeAreaBottom: homeIndicator,
            keyboardTop: keyboardTop,
            maxHeight: maxHeight
        )
    }
}
