//
//  ComposerCaretTests.swift
//  TanyaAISandboxTests
//
//  Created by Wendra on 16/10/26.
//

import DesignKit
import SwiftUI
import Testing

extension HostWindowTests {
    @MainActor
    struct ComposerCaretTests {
        @Test
        func emptyCaretMatchesTypedCaretAcrossFontCatalogAndAfterClearing() throws {
            try FontFace.registerFonts()
            for face in FontFace.allCases {
                let fixture = try HostWindowFixture(ComposerFixture(fontFace: face).frame(width: 343))
                defer { fixture.close() }
                let editor = try #require(findEditor(in: fixture.controller.view))
                #expect(editor.becomeFirstResponder())
                fixture.settle()
                let emptyCaret = editor.caretRect(for: editor.beginningOfDocument)
                let emptyHeight = editor.bounds.height
                editor.insertText("Ag")
                fixture.settle()
                let typedCaret = editor.caretRect(for: editor.beginningOfDocument)
                #expect(emptyCaret == typedCaret, "\(face.rawValue)")
                editor.deleteBackward()
                editor.deleteBackward()
                fixture.settle()
                #expect(editor.text == "")
                #expect(abs(editor.bounds.height - emptyHeight) <= 0.01)
                #expect(editor.caretRect(for: editor.beginningOfDocument) == typedCaret, "\(face.rawValue)")
            }
        }

        private func findEditor(in view: UIView) -> BoundedTextView? {
            if let editor = view as? BoundedTextView { return editor }
            return view.subviews.lazy.compactMap { self.findEditor(in: $0) }.first
        }
    }
}

@MainActor
private struct ComposerFixture: View {
    @State
    private var text = ""
    let fontFace: FontFace

    var body: some View {
        MessageComposer(
            text: $text, placeholder: "Ask about your finances", actionLabel: "Send", fontFace: fontFace, onSend: {}
        )
    }
}
