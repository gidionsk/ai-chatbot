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
    /// Hanya titik bergerak (menunggu pertanyaan tampil) yang mengunci draft; saat stop nasabah boleh mengetik
    /// pertanyaan berikutnya. Diuji di window karena editor UIKit baru dibuat saat tampil.
    @MainActor
    struct ComposerActionTests {
        @Test(arguments: [
            (MessageComposerAction.send, true), (.loading, false), (.stop, true), (.stopping, true)
        ])
        func onlyLoadingLocksTheDraft(action: MessageComposerAction, isEditable: Bool) throws {
            let fixture = try HostWindowFixture(ActionFixture(action: action).frame(width: 343))
            defer { fixture.close() }
            let editor = try #require(findEditor(in: fixture.controller.view))
            let range = NSRange(location: 0, length: 0)
            let isAccepted = editor.delegate?.textView?(editor, shouldChangeTextIn: range, replacementText: "x")
            #expect(isAccepted == isEditable, "\(action)")
            #expect(editor.accessibilityTraits.contains(.notEnabled) == !isEditable, "\(action)")
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
