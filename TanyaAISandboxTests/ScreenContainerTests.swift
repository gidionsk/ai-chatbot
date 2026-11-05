//
//  ScreenContainerTests.swift
//  TanyaAISandboxTests
//
//  Created by Wendra on 16/10/26.
//

import DesignKit
import SwiftUI
import Testing

extension HostWindowTests {
    @MainActor
    struct ScreenContainerTests {
        @Test
        func multipleBuilderChildrenShareMarginsAndHeaderInset() throws {
            let first = FrameProbe()
            let second = FrameProbe()
            let content = ScreenContainer(
                title: "General screen", backLabel: "Back", onBack: {},
                content: {
                    FrameSample(probe: first)
                    FrameSample(probe: second)
                }
            )
            let fixture = try HostWindowFixture(content)
            defer { fixture.close() }
            let firstFrame = try #require(first.frame)
            let secondFrame = try #require(second.frame)
            #expect(abs(secondFrame.minY - firstFrame.maxY) <= 1)
            #expect(abs(firstFrame.minX - FigmaSize.spacingLarge.scaledToArtwork) <= 1)
            #expect(abs(secondFrame.minX - firstFrame.minX) <= 1)
            #expect(abs(secondFrame.width - firstFrame.width) <= 1)
            // Header mulai dari tepi atas layar seperti navigation bar host, bukan dari safe area.
            let isNotched = ScreenHeader.isNotched(safeAreaTop: fixture.controller.view.safeAreaInsets.top)
            let expectedTop = ScreenHeader.height(isNotched: isNotched) + FigmaSize.spacingLarge.scaledToArtwork
            #expect(abs(firstFrame.minY - expectedTop) <= 1)
        }
    }
}

private final class FrameProbe {
    var frame: CGRect?
}

private struct FrameSample: View {
    let probe: FrameProbe
    var body: some View {
        Color.clear.frame(height: 50)
            .background {
                GeometryReader { geometry in
                    Color.clear.onAppear { probe.frame = geometry.frame(in: .global) }
                }
            }
    }
}
