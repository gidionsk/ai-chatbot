//
//  ScrollProgressTests.swift
//  DesignKitTests
//
//  Created by Wendra on 5/11/26.
//

import CoreGraphics
import DesignKit
import Testing

struct ScrollProgressTests {
    @Test
    func progressRisesWithTheOffsetAndStopsAtOne() {
        #expect(CGFloat.scrollProgress(offset: .zero, distance: 100) == .zero)
        #expect(CGFloat.scrollProgress(offset: 50, distance: 100) == 0.5)
        #expect(CGFloat.scrollProgress(offset: 300, distance: 100) == 1)
    }

    @Test
    func bounceAndTinyOffsetsCountAsTheTop() {
        #expect(CGFloat.scrollProgress(offset: -40, distance: 100) == .zero)
        #expect(CGFloat.scrollProgress(offset: 0.2, distance: 100) == .zero)
    }

    @Test
    func aZeroDistanceDoesNotDivideByZero() {
        #expect(CGFloat.scrollProgress(offset: 10, distance: .zero) == 1)
    }
}
