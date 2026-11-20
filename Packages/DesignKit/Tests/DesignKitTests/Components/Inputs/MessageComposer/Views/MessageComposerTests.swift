//
//  MessageComposerTests.swift
//  DesignKit
//
//  Created by Wendra on 10/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Tombol lampiran di dalam kartu seukuran tombol kirim, jadi tinggi composer tetap. Field nonaktif tidak bisa
/// diketik dan melepas keyboard yang sedang terbuka.
@MainActor
@Suite(.serialized)
struct MessageComposerTests {
    @Test
    func attachmentKeepsTheComposerHeight() throws {
        try FontFace.registerFonts()
        let plain = size(of: composer(attachment: nil))
        let attached = size(of: composer(attachment: MessageComposerAttachment(label: "Lampirkan") {}))
        #expect(abs(attached.height - plain.height) <= 0.5)
    }

    @Test
    func disabledInputIsNotEditableAndReleasesTheKeyboard() async throws {
        try FontFace.registerFonts()
        let model = ComposerInputModel()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 800))
        window.rootViewController = UIHostingController(rootView: ComposerInputHost(model: model))
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        window.layoutIfNeeded()
        await waitUntil { editor(in: window) != nil }
        let editor = try #require(editor(in: window))
        #expect(editor.isEditable)
        editor.becomeFirstResponder()
        await waitUntil { editor.isFirstResponder }
        model.isInputEnabled = false
        await waitUntil { !editor.isEditable }
        #expect(!editor.isFirstResponder)
        model.isInputEnabled = true
        await waitUntil { editor.isEditable }
    }
}

// MARK: - Helpers

private extension MessageComposerTests {
    func composer(attachment: MessageComposerAttachment?) -> some View {
        MessageComposer(
            text: .constant(String()), placeholder: "Tanya", actionLabel: "Kirim", attachment: attachment, onSend: {}
        )
    }

    func editor(in window: UIWindow) -> BoundedTextView? {
        window.scrollViews.compactMap { $0 as? BoundedTextView }.first
    }

    func size(of content: some View) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: 375, height: 800))
    }
}

/// Status input yang diubah test setelah composer tampil.
@MainActor
private final class ComposerInputModel: ObservableObject {
    @Published var isInputEnabled = true
}

private struct ComposerInputHost: View {
    @ObservedObject var model: ComposerInputModel

    var body: some View {
        MessageComposer(
            text: .constant("Halo"),
            placeholder: "Tanya",
            actionLabel: "Kirim",
            isInputEnabled: model.isInputEnabled,
            onSend: {}
        )
    }
}
