//
//  ColorHexTests.swift
//  DesignKit
//
//  Created by Wendra on 15/10/26.
//

import SwiftUI
import Testing

@testable import DesignKit

struct ColorHexTests {
    @Test
    func rgbFormsAndARGBAlpha() {
        expectComponents(Color(hex: " #3aF "), red: 51 / 255, green: 170 / 255, blue: 1, alpha: 1)
        expectComponents(Color(hex: "336699"), red: 51 / 255, green: 102 / 255, blue: 153 / 255, alpha: 1)
        expectComponents(Color(hex: "80336699"), red: 51 / 255, green: 102 / 255, blue: 153 / 255, alpha: 128 / 255)
    }

    @Test(arguments: ["", "##FFF", "+FFF", "12", "12345", "GGGGGG", "FFFFFFoops", "ＦＦＦ"])
    func malformedStringsUseTheRequestedFallback(text: String) {
        #expect(UIColor(Color(hex: text, fallback: .red)) == UIColor(Color.red))
    }

    @Test
    func malformedStringWithoutFallbackIsClear() {
        expectComponents(Color(hex: "invalid"), red: 0, green: 0, blue: 0, alpha: 0)
    }
}

// MARK: - Helpers

private extension ColorHexTests {
    func expectComponents(
        _ color: Color, red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        var actualRed: CGFloat = 0
        var actualGreen: CGFloat = 0
        var actualBlue: CGFloat = 0
        var actualAlpha: CGFloat = 0
        let isReadable = UIColor(color).getRed(&actualRed, green: &actualGreen, blue: &actualBlue, alpha: &actualAlpha)
        #expect(isReadable, sourceLocation: sourceLocation)
        let actual = [actualRed, actualGreen, actualBlue, actualAlpha]
        let differences = zip(actual, [red, green, blue, alpha]).map { abs($0 - $1) }
        #expect(differences.allSatisfy { $0 <= 0.001 }, "\(actual)", sourceLocation: sourceLocation)
    }
}
