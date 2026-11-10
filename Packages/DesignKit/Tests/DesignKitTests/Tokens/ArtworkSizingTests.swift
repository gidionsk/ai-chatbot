//
//  ArtworkSizingTests.swift
//  DesignKit
//
//  Created by Wendra on 15/10/26.
//

import Testing
import UIKit

@testable import DesignKit

struct ArtworkSizingTests {
    @Test(arguments: [320, 375, 390, 430, 768, 1_024] as [CGFloat])
    func uncappedHostFormulaAcrossDeviceWidths(width: CGFloat) {
        for value: CGFloat in [0, 0.5, 2, 8, 16, 24, 56] {
            #expect(value.scaledToArtwork(ratio: 375 / width) == (value * width / 375).rounded())
        }
    }

    @Test
    func screenScalingUsesDesignValuesWithoutMinimumOverrides() {
        #expect(CGFloat(16).scaledToArtwork == (16 / (375 / UIScreen.main.bounds.width)).rounded())
        #expect(CGFloat(24).scaledToArtwork == (24 / (375 / UIScreen.main.bounds.width)).rounded())
        #expect(CGFloat(0.1).scaledToArtwork(ratio: 1) == 0)
        #expect(CGFloat.nan.scaledToArtwork == 0)
        #expect(CGFloat.infinity.scaledToArtwork == 0)
        #expect(CGFloat(16).scaledToArtwork(ratio: 0) == 0)
    }
}
