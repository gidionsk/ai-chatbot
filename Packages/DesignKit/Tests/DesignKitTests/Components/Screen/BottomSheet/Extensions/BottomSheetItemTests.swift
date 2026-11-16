//
//  BottomSheetItemTests.swift
//  DesignKitTests
//
//  Created by Wendra on 14/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// `.bottomSheet(item:)`: sheet mengikuti ada tidaknya nilai, isinya dibangun dari nilai itu, dan nilai lain
/// membangun isi baru. Berurutan karena memakai window.
@MainActor
@Suite(.serialized)
struct BottomSheetItemTests {
    @Test
    func presenceFollowsTheOptionalValue() {
        var item: String? = "format"
        let binding = Binding(get: { item }, set: { item = $0 })
        let isPresent = binding.isPresent()
        #expect(isPresent.wrappedValue)
        isPresent.wrappedValue = true
        #expect(item == "format", "diisi true tidak mengubah nilainya")
        isPresent.wrappedValue = false
        #expect(item == nil)
        #expect(!isPresent.wrappedValue)
    }

    @Test
    func theContentIsBuiltFromTheItemAndRebuiltForAnotherItem() async {
        var builtItems: [String] = []
        let host = UIHostingController(rootView: page(item: nil) { builtItems.append($0) })
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        host.view.layoutIfNeeded()
        #expect(builtItems.isEmpty, "tanpa nilai, isi tidak dibangun")
        host.rootView = page(item: "format") { builtItems.append($0) }
        await waitUntil { builtItems == ["format"] }
        host.rootView = page(item: "rekening") { builtItems.append($0) }
        await waitUntil { builtItems == ["format", "rekening"] }
    }

    /// Daftar panjang diganti daftar panjang lain: pilihan di daftar baru tetap digulir ke layar, sama seperti saat
    /// daftar itu dibuka langsung.
    @Test
    func anotherItemScrollsToItsOwnFocus() async throws {
        try FontFace.registerFonts()
        let host = UIHostingController(rootView: lists(item: "tanpa pilihan"))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        await waitUntil { window.scrollViews.contains { $0.isScrollEnabled } }
        #expect(window.scrollViews.allSatisfy { $0.contentOffset.y <= 0.5 })
        host.rootView = lists(item: "pilihan 30")
        await waitUntil { window.scrollViews.contains { $0.contentOffset.y > 0.5 } }
    }
}

// MARK: - Helpers

private extension BottomSheetItemTests {
    /// Dua daftar 40 baris; hanya "pilihan 30" yang punya pilihan sebelumnya, di baris ke-30.
    func lists(item: String) -> some View {
        let options = (0..<40).map { OptionItem(id: String($0), title: "Rekening \($0)") }
        return Color.clear.bottomSheet(item: .constant(Optional(item)), closeLabel: "Tutup") { value in
            OptionList(
                title: value,
                items: options,
                selectedIDs: value == "pilihan 30" ? ["30"] : [],
                onSelect: { _ in }
            )
        }
    }

    func page(item: String?, onBuild: @escaping (String) -> Void) -> some View {
        Color.clear.bottomSheet(item: .constant(item), closeLabel: "Tutup") { value in
            Color.clear.frame(height: 80).onAppear { onBuild(value) }
        }
    }
}
