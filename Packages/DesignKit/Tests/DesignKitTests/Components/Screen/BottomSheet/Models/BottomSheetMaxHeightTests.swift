//
//  BottomSheetMaxHeightTests.swift
//  DesignKitTests
//
//  Created by Wendra on 12/11/26.
//

import CoreGraphics
import Testing

@testable import DesignKit

/// Batas bawaan sampai di bawah status bar; batas dari tinggi layar tidak pernah melewatinya dan tidak negatif.
struct BottomSheetMaxHeightTests {
    @Test
    func theDefaultLimitStopsBelowTheStatusBar() {
        #expect(BottomSheetMaxHeight.belowStatusBar.resolved(screenHeight: 874, limit: 812) == 812)
    }

    @Test(arguments: [
        (CGFloat(0.5), CGFloat(437)),
        (0.6, 524.4),
        (1, 812),
        (1.5, 812),
        (-0.2, .zero)
    ])
    func aScreenFractionIsMeasuredFromTheWholeScreenAndNeverPassesTheStatusBar(fraction: CGFloat, expected: CGFloat) {
        let height = BottomSheetMaxHeight.screenFraction(fraction).resolved(screenHeight: 874, limit: 812)
        #expect(abs(height - expected) <= 0.01)
    }
}
