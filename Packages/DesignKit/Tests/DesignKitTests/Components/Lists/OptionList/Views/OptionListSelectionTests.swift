//
//  OptionListSelectionTests.swift
//  DesignKitTests
//
//  Created by Wendra on 14/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Centang sementara milik `OptionList`, tetapi pilihan dari pemakai tetap sumbernya: bila pemakai mengganti
/// `selectedIDs` selagi daftar tampil, centangnya ikut berganti. Berurutan karena memakai window.
@MainActor
@Suite(.serialized)
struct OptionListSelectionTests {
    private let items = (0..<3).map { OptionItem(id: String($0), title: "Rekening \($0)") }
    private let frame = CGRect(x: 0, y: 0, width: 375, height: 400)

    @Test
    func checksFollowANewCallerSelection() async throws {
        try FontFace.registerFonts()
        let host = UIHostingController(rootView: list(selectedIDs: ["0"]))
        let window = UIWindow(frame: frame)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let first = snapshot(of: window)
        let expected = freshSnapshot(selectedIDs: ["2"])
        try #require(first != expected, "gambar harus membedakan baris yang tercentang")
        host.rootView = list(selectedIDs: ["2"])
        await waitUntil { snapshot(of: window) == expected }
    }
}

// MARK: - Helpers

private extension OptionListSelectionTests {
    func list(selectedIDs: [String]) -> some View {
        OptionList(title: "Rekening", items: items, selectedIDs: selectedIDs, onSelect: { _ in })
            .frame(maxHeight: .infinity, alignment: .top)
    }

    func freshSnapshot(selectedIDs: [String]) -> Data {
        let window = UIWindow(frame: frame)
        window.rootViewController = UIHostingController(rootView: list(selectedIDs: selectedIDs))
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        return snapshot(of: window)
    }

    func snapshot(of window: UIWindow) -> Data {
        window.layoutIfNeeded()
        return UIGraphicsImageRenderer(bounds: window.bounds).pngData { context in
            window.layer.render(in: context.cgContext)
        }
    }
}
