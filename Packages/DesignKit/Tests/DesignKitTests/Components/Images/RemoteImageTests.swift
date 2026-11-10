//
//  RemoteImageTests.swift
//  DesignKit
//
//  Created by Wendra on 27/10/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Kontrak `RemoteImage` di atas Kingfisher: kapan placeholder dan fallback tampil.
/// Berurutan karena setiap test membuka window dan menunggu hasil unduhan.
@MainActor
@Suite(.serialized)
struct RemoteImageTests {
    @Test
    func failedDownloadReplacesThePlaceholderWithTheFallback() async {
        var isPlaceholderShown = false
        var isFallbackShown = false
        let missing = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let window = show(
            RemoteImage(
                url: missing, pointSize: 24,
                placeholder: { Color.clear.onAppear { isPlaceholderShown = true } },
                fallback: { Color.clear.onAppear { isFallbackShown = true } }
            )
        )
        defer { window.isHidden = true }
        await waitUntil { isFallbackShown }
        #expect(isPlaceholderShown)
    }

    @Test
    func missingURLShowsTheFallback() async {
        var isFallbackShown = false
        let window = show(
            RemoteImage(
                url: nil, pointSize: 24, placeholder: { Color.clear },
                fallback: { Color.clear.onAppear { isFallbackShown = true } }
            )
        )
        defer { window.isHidden = true }
        await waitUntil { isFallbackShown }
    }
}

// MARK: - Helpers

private extension RemoteImageTests {
    func show(_ content: some View) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.rootViewController = UIHostingController(rootView: content.frame(width: 24, height: 24))
        window.makeKeyAndVisible()
        window.rootViewController?.view.layoutIfNeeded()
        return window
    }
}
