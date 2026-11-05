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

        /// Konten bisa menghitung posisi scroll sendiri; konten yang lebih pendek dari layar dianggap sudah di bawah.
        @Test
        func contentReadsTheViewportBelowTheHeader() throws {
            let probe = ViewportProbe()
            let content = ScreenContainer(
                title: "General screen", backLabel: "Back", onBack: {}, content: { ViewportSample(probe: probe) }
            )
            let fixture = try HostWindowFixture(content)
            defer { fixture.close() }
            let viewport = try #require(probe.viewport)
            #expect(viewport.height > .zero)
            #expect(viewport.headerHeight > .zero)
            #expect(viewport.isNearBottom)
        }
    }
}

private final class ViewportProbe {
    var viewport: ScreenViewport?
}

private struct ViewportSample: View {
    @Environment(\.screenViewport) private var viewport
    let probe: ViewportProbe

    var body: some View {
        Color.clear.frame(height: 50)
            .onAppear { probe.viewport = viewport }
            .onChange(of: viewport) { probe.viewport = $0 }
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
