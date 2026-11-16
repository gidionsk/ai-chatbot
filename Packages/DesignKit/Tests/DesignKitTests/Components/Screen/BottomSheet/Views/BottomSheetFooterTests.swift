//
//  BottomSheetFooterTests.swift
//  DesignKitTests
//
//  Created by Wendra on 14/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// `bottomSheetFooter`: di luar sheet footer tampil di bawah isi; di dalam sheet tingginya ikut dihitung dan footer
/// menempel di tepi bawah selama isi panjang di-scroll. Berurutan karena memakai window.
@MainActor
@Suite(.serialized)
struct BottomSheetFooterTests {
    private let width: CGFloat = 375
    private let rowHeight: CGFloat = 44
    private let footerHeight: CGFloat = 50

    @Test
    func outsideASheetTheFooterSitsBelowTheContent() {
        let content = Color.clear.frame(height: 100).bottomSheetFooter { Color.clear.frame(height: footerHeight) }
        #expect(abs(size(of: content).height - 100 - footerHeight) <= 0.5)
    }

    @Test
    func theSheetCountsTheFooterInItsHeight() {
        let bare = size(of: sheet(rows: 3, maxHeight: .infinity, footer: { EmptyView() }))
        let footed = size(of: sheet(rows: 3, maxHeight: .infinity) { Color.clear.frame(height: footerHeight) })
        #expect(abs(footed.height - bare.height - footerHeight) <= 0.5)
    }

    /// 40 baris di sheet setinggi 400: daftar belum digeser, tetapi footer sudah di tepi bawah area isi, dan ujung isi
    /// memesan tempat setinggi footer supaya baris terakhir bisa digulir sampai di atasnya.
    @Test
    func theFooterStaysAtTheBottomWhileLongContentScrolls() async throws {
        var frames: [CGRect] = []
        let probe = FrameProbe { frames.append($0) }
        let root = sheet(rows: 40, maxHeight: 400) { Color.clear.frame(height: footerHeight).background(probe) }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 812))
        window.rootViewController = UIHostingController(rootView: root)
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        await waitUntil { window.scrollViews.first?.isScrollEnabled == true }
        let scrollView = try #require(window.scrollViews.first)
        let bottom = scrollView.convert(scrollView.bounds, to: nil).maxY
        await waitUntil { frames.contains { abs($0.maxY - bottom) <= 0.5 } }
        #expect(scrollView.contentOffset.y <= 0.5, "daftar masih di atas")
        #expect(abs(scrollView.contentSize.height - 40 * rowHeight - footerHeight) <= 0.5)
    }

    /// Isi yang dinonaktifkan pemakai menonaktifkan juga footer yang ditempel wadah, walau footer digambar di luar isi.
    @Test
    func aDisabledContentDisablesItsPinnedFooter() async {
        var states: [Bool] = []
        let root = BottomSheet(
            closeLabel: "Tutup",
            bottomInset: .zero,
            onClose: {},
            content: {
                Color.clear.frame(height: rowHeight)
                    .bottomSheetFooter { EnabledProbe { states.append($0) }.frame(height: footerHeight) }
                    .disabled(true)
            }
        )
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: 812))
        window.rootViewController = UIHostingController(rootView: root)
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        await waitUntil { states.count >= 2 }
        #expect(!states.contains(true), "footer yang ditempel ikut nonaktif")
    }
}

// MARK: - Helpers

private extension BottomSheetFooterTests {
    func sheet<Footer: View>(
        rows: Int,
        maxHeight: CGFloat,
        @ViewBuilder footer: @escaping () -> Footer
    ) -> some View {
        BottomSheet(
            closeLabel: "Tutup",
            bottomInset: .zero,
            maxHeight: maxHeight,
            onClose: {},
            content: {
                VStack(spacing: .zero) {
                    ForEach(0..<rows, id: \.self) { _ in Color.clear.frame(height: rowHeight) }
                }
                .bottomSheetFooter(footer: footer)
            }
        )
    }

    func size(of content: some View) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: width, height: 800))
    }
}
