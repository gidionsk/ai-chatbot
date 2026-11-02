//
//  ScrollProgressTests.swift
//  TanyaAISandboxTests
//
//  Created by Wendra on 16/10/26.
//

import DesignKit
import SwiftUI
import Testing

extension HostWindowTests {
    @MainActor
    struct ScrollProgressTests {
        /// Progres naik sebanding offset sampai `distance`, lalu diam di 1 tanpa laporan baru; kembali ke atas = 0.
        @Test
        func nestedObserversOnlyReportTheirOwnProgress() throws {
            let outer = ProgressProbe()
            let inner = ProgressProbe()
            let fixture = try HostWindowFixture(NestedScrollFixture(outer: outer, inner: inner))
            defer { fixture.close() }
            let scrollViews = scrollViews(in: fixture.controller.view)
            #expect(scrollViews.count == 2)
            let outerScroll = try #require(scrollViews.max { $0.bounds.height < $1.bounds.height })
            let innerScroll = try #require(scrollViews.min { $0.bounds.height < $1.bounds.height })
            #expect(outer.values == [0])
            #expect(inner.values == [0])
            scroll(outerScroll, to: 0.2, fixture: fixture)
            #expect(outer.values == [0], "offset di bawah toleransi masih dianggap di atas")
            scroll(outerScroll, to: NestedScrollFixture.outerDistance / 2, fixture: fixture)
            #expect(outer.isClose(to: [0, 0.5]))
            for offset: CGFloat in [100, 160, 200, 400] {
                scroll(outerScroll, to: offset, fixture: fixture)
            }
            #expect(outer.isClose(to: [0, 0.5, 1]), "setelah solid penuh tidak ada laporan baru")
            #expect(inner.values == [0])
            scroll(innerScroll, to: 80, fixture: fixture)
            #expect(inner.isClose(to: [0, 1]))
            #expect(outer.isClose(to: [0, 0.5, 1]))
            scroll(innerScroll, to: 0, fixture: fixture)
            #expect(inner.isClose(to: [0, 1, 0]))
            scroll(outerScroll, to: 0, fixture: fixture)
            #expect(outer.isClose(to: [0, 0.5, 1, 0]), "kembali ke posisi teratas = transparan penuh")
        }

        private func scroll(_ view: UIScrollView, to offset: CGFloat, fixture: HostWindowFixture) {
            view.setContentOffset(CGPoint(x: 0, y: offset - view.adjustedContentInset.top), animated: false)
            fixture.settle()
        }

        private func scrollViews(in view: UIView) -> [UIScrollView] {
            let current = (view as? UIScrollView).map { [$0] } ?? []
            return current + view.subviews.flatMap { scrollViews(in: $0) }
        }
    }
}

private final class ProgressProbe {
    var values: [CGFloat] = []
    func record(_ progress: CGFloat) { values.append(progress) }

    func isClose(to expected: [CGFloat]) -> Bool {
        values.count == expected.count && zip(values, expected).allSatisfy { abs($0 - $1) < 0.01 }
    }
}

private struct NestedScrollFixture: View {
    static let outerDistance: CGFloat = 100
    static let innerDistance: CGFloat = 40
    @State
    private var outerSpaceID = UUID()
    @State
    private var innerSpaceID = UUID()
    let outer: ProgressProbe
    let inner: ProgressProbe

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScrollView {
                    Color.clear.frame(height: 1_600)
                        .onScrollProgressChange(in: innerSpaceID, distance: Self.innerDistance, perform: inner.record)
                }
                .coordinateSpace(name: innerSpaceID)
                .frame(height: 200)
                Color.clear.frame(height: 1_600)
            }
            .onScrollProgressChange(in: outerSpaceID, distance: Self.outerDistance, perform: outer.record)
        }
        .coordinateSpace(name: outerSpaceID)
    }
}
