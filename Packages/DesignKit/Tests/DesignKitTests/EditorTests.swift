//
//  EditorTests.swift
//  DesignKit
//
//  Created by Wendra on 15/10/26.
//

import SwiftUI
import Testing

@testable import DesignKit

@MainActor
struct EditorTests {
    @Test
    func editorGrowsToFourLinesThenScrollsAndShrinksWhenCleared() throws {
        try FontFace.registerFonts()
        let editor = BoundedTextView(frame: CGRect(x: 0, y: 0, width: 220, height: 300))
        editor.font = FontFace.openSansRegular.font(size: 16)
        editor.textContainerInset = .zero
        editor.textContainer.lineFragmentPadding = 0
        editor.isScrollEnabled = false
        editor.text = "One"
        editor.layoutSubviews()
        let firstHeight = editor.intrinsicContentSize.height
        editor.text = "One\nTwo\nThree\nFour"
        editor.remeasure()
        let fourthHeight = editor.intrinsicContentSize.height
        #expect(fourthHeight > firstHeight)
        editor.text = (editor.text ?? "") + "\nFive\n" + String(repeating: "m", count: 128)
        editor.remeasure()
        #expect(abs(editor.intrinsicContentSize.height - fourthHeight) <= 1)
        #expect(editor.isScrollEnabled)
        #expect(editor.intrinsicContentSize.width == UIView.noIntrinsicMetric)
        editor.text = ""
        editor.remeasure()
        #expect(editor.intrinsicContentSize.height < fourthHeight)
        #expect(!editor.isScrollEnabled)
    }

    @Test
    func widthChangeRemeasuresWhileInternalScrollKeepsHeight() throws {
        try FontFace.registerFonts()
        let editor = BoundedTextView(frame: CGRect(x: 0, y: 0, width: 320, height: 300))
        editor.font = FontFace.openSansRegular.font(size: 14)
        editor.textContainerInset = .zero
        editor.textContainer.lineFragmentPadding = 0
        editor.text = String(repeating: "word ", count: 12)
        editor.layoutSubviews()
        let wideHeight = editor.intrinsicContentSize.height
        editor.frame.size.width = 120
        editor.layoutSubviews()
        let narrowHeight = editor.intrinsicContentSize.height
        #expect(narrowHeight > wideHeight)
        editor.contentOffset.y += 10
        editor.layoutSubviews()
        #expect(editor.intrinsicContentSize.height == narrowHeight)
    }

    @Test
    func composerWrapsWithoutGrowingHorizontallyAcrossTextSizeSettings() throws {
        try FontFace.registerFonts()
        for width: CGFloat in [320, 375, 430] {
            for category: ContentSizeCategory in [.large, .accessibilityExtraExtraExtraLarge] {
                let content = MessageComposer(
                    text: .constant(String(repeating: "中文 English ", count: 20)),
                    placeholder: "咨询财务及服务…", actionLabel: "发送消息", onSend: {}
                )
                .environment(\.sizeCategory, category)
                let controller = UIHostingController(rootView: content)
                controller.view.frame = CGRect(x: 0, y: 0, width: width, height: 800)
                controller.view.layoutIfNeeded()
                let size = controller.sizeThatFits(in: CGSize(width: width, height: 2_000))
                #expect(size.width <= width + 1)
                #expect(size.height.isFinite && size.height > 0 && size.height < 1_000)
            }
        }
    }

    @Test
    func largePasteStaysBoundedAndReleasesEditor() async throws {
        try FontFace.registerFonts()
        weak var releasedEditor: BoundedTextView?
        autoreleasepool {
            let editor = BoundedTextView(frame: CGRect(x: 0, y: 0, width: 220, height: 300))
            releasedEditor = editor
            editor.font = FontFace.openSansRegular.font(size: 14)
            editor.textContainerInset = .zero
            editor.textContainer.lineFragmentPadding = 0
            editor.isScrollEnabled = false
            editor.text = String(repeating: "中文 English message ", count: 1_000)
            editor.layoutSubviews()
            let lineHeight = editor.font?.lineHeight ?? 0
            #expect(abs(editor.intrinsicContentSize.height - ceil(lineHeight * 4)) <= 1)
            #expect(editor.isScrollEnabled)
            editor.text = ""
            editor.remeasure()
            #expect(editor.intrinsicContentSize.height < ceil(lineHeight * 4))
            #expect(!editor.isScrollEnabled)
        }
        await waitUntil(timeout: 2) { releasedEditor == nil }
    }

    /// Input dikunci (titik bergerak di composer): ketikan dan tempel ditolak; tampilan diuji di sandbox.
    @Test(arguments: [true, false])
    func lockedInputRejectsEveryChange(isEditable: Bool) {
        let input = GrowingTextInput(
            text: .constant("draft"), font: .systemFont(ofSize: 14), textColor: .black,
            isEditable: isEditable, accessibilityLabel: "Tanya"
        )
        let range = NSRange(location: 5, length: 0)
        let isAccepted = input.makeCoordinator().textView(UITextView(), shouldChangeTextIn: range, replacementText: "x")
        #expect(isAccepted == isEditable)
    }
}
