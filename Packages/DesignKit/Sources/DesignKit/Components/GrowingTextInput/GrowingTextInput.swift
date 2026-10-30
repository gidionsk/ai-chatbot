//
//  GrowingTextInput.swift
//  DesignKit
//
//  Created by Wendra on 15/10/26.
//

import SwiftUI
import UIKit

/// The UIKit bridge owns measurement and selection; the caller owns the draft and font.
@MainActor
public struct GrowingTextInput: UIViewRepresentable {
    @Binding
    private var text: String
    private let font: UIFont
    private let textColor: UIColor
    private let lineSpacing: CGFloat
    private let isEditable: Bool
    private let accessibilityLabel: String

    /// `isEditable` false menolak setiap perubahan teks tanpa melepas fokus, jadi keyboard tidak turun-naik
    /// dan layout tidak melompat saat kunci hanya sebentar.
    public init(
        text: Binding<String>, font: UIFont, textColor: UIColor,
        lineSpacing: CGFloat = .zero, isEditable: Bool = true, accessibilityLabel: String
    ) {
        self._text = text
        self.font = font
        self.textColor = textColor
        self.lineSpacing = lineSpacing
        self.isEditable = isEditable
        self.accessibilityLabel = accessibilityLabel
    }

    public func makeUIView(context: Context) -> BoundedTextView {
        let editor = BoundedTextView()
        editor.delegate = context.coordinator
        editor.backgroundColor = .clear
        editor.textContainerInset = .zero
        editor.textContainer.lineFragmentPadding = .zero
        editor.adjustsFontForContentSizeCategory = false
        editor.isScrollEnabled = false
        editor.text = text
        editor.setContentHuggingPriority(.defaultLow, for: .horizontal)
        applyStyle(to: editor)
        applyAccessibility(to: editor)
        return editor
    }

    public func updateUIView(_ editor: BoundedTextView, context: Context) {
        context.coordinator.parent = self
        applyAccessibility(to: editor)
        let isStyleChanged = editor.font != font || editor.textColor != textColor || editor.lineSpacing != lineSpacing
        let isTextChanged = editor.text != text
        if isTextChanged { editor.text = text }
        guard isStyleChanged || isTextChanged else { return }
        applyStyle(to: editor)
        editor.remeasure()
    }

    public func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    public static func dismantleUIView(_ editor: BoundedTextView, coordinator: Coordinator) {
        editor.delegate = nil
    }

    public final class Coordinator: NSObject, UITextViewDelegate {
        var parent: GrowingTextInput
        init(parent: GrowingTextInput) { self.parent = parent }

        /// Ketikan, tempel, dikte, dan teks IME ditolak selama tidak bisa diubah.
        public func textView(
            _ editor: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String
        ) -> Bool {
            parent.isEditable
        }

        public func textViewDidChange(_ editor: UITextView) {
            // UITextView.text bertipe String!; baca sebagai optional agar tidak ada unwrap paksa.
            parent.text = editor.text ?? String()
            (editor as? BoundedTextView)?.remeasure()
        }
    }
}

// MARK: - Helpers

private extension GrowingTextInput {
    func applyAccessibility(to editor: BoundedTextView) {
        editor.accessibilityLabel = accessibilityLabel
        editor.isEditingLocked = !isEditable
    }

    func applyStyle(to editor: BoundedTextView) {
        guard editor.markedTextRange == nil else { return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = max(.zero, lineSpacing)
        editor.lineSpacing = paragraph.lineSpacing
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: textColor, .paragraphStyle: paragraph
        ]
        editor.font = font
        editor.textColor = textColor
        editor.typingAttributes = attributes
        let selection = editor.selectedRange
        editor.textStorage.addAttributes(
            attributes, range: NSRange(location: .zero, length: editor.textStorage.length)
        )
        editor.selectedRange = selection
    }
}
