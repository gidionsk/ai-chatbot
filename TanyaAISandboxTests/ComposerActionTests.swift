//
//  ComposerActionTests.swift
//  TanyaAISandboxTests
//
//  Created by Wendra on 30/10/26.
//

import DesignKit
import SwiftUI
import Testing

extension HostWindowTests {
    /// Tidak ada fase yang mengunci draft: saat stop nasabah boleh mengetik pertanyaan berikutnya. Diuji di
    /// window karena editor UIKit baru dibuat saat tampil.
    @MainActor
    struct ComposerActionTests {
        @Test(arguments: [MessageComposerAction.send, .stop, .stopping])
        func everyActionKeepsTheDraftEditable(action: MessageComposerAction) throws {
            let fixture = try HostWindowFixture(ActionFixture(action: action).frame(width: 343))
            defer { fixture.close() }
            let editor = try #require(findEditor(in: fixture.controller.view))
            let range = NSRange(location: 0, length: 0)
            let isAccepted = editor.delegate?.textView?(editor, shouldChangeTextIn: range, replacementText: "x")
            #expect(isAccepted ?? true, "\(action)")
            #expect(editor.isEditable, "\(action)")
            #expect(!editor.accessibilityTraits.contains(.notEnabled), "\(action)")
        }

        private func findEditor(in view: UIView) -> BoundedTextView? {
            if let editor = view as? BoundedTextView { return editor }
            return view.subviews.lazy.compactMap { self.findEditor(in: $0) }.first
        }
    }
}

@MainActor
private struct ActionFixture: View {
    @State
    private var text = "Pertanyaan berikutnya"
    let action: MessageComposerAction

    var body: some View {
        MessageComposer(
            text: $text, placeholder: "Tanya", actionLabel: "Aksi", action: action, onSend: {}, onStop: {}
        )
    }
}
