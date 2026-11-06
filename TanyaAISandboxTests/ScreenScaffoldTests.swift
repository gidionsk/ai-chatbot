//
//  ScreenScaffoldTests.swift
//  TanyaAISandboxTests
//
//  Created by Wendra on 6/11/26.
//

import DesignKit
import SwiftUI
import Testing

extension HostWindowTests {
    @MainActor
    struct ScreenScaffoldTests {
        /// Konten mulai dari tepi atas layar, jadi tinggi header dipakai sebagai inset awalnya.
        @Test
        func contentStartsBelowTheHeaderWithTheReportedHeight() throws {
            let probe = FrameProbe()
            let content = ScreenScaffold(
                title: "General screen", backLabel: "Back", scrollProgress: .zero, onBack: {},
                content: { FrameSample(probe: probe).padding(.top, $0) }, trailing: { EmptyView() },
                footer: { EmptyView() }, background: { EmptyView() }
            )
            let fixture = try HostWindowFixture(content)
            defer { fixture.close() }
            let frame = try #require(probe.frame)
            let isNotched = ScreenHeader.isNotched(safeAreaTop: fixture.controller.view.safeAreaInsets.top)
            #expect(abs(frame.minY - ScreenHeader.height(isNotched: isNotched)) <= 1)
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
