//
//  FontTests.swift
//  DesignKit
//
//  Created by Wendra on 15/10/26.
//

import CoreText
import SwiftUI
import Testing
import UIKit

@testable import DesignKit

struct FontTests {
    @Test
    func bundledFontsRegisterWithTheirRealPostScriptNames() throws {
        try FontFace.registerFonts()
        try FontFace.registerFonts()
        let expected: [(FontFace, String)] = [
            (.firaSansRegular, "FiraSans-Regular"), (.firaSansMedium, "FiraSans-Medium"),
            (.firaSansSemiBold, "FiraSans-SemiBold"), (.firaSansBold, "FiraSans-Bold"),
            (.firaSansItalic, "FiraSans-Italic"), (.firaSansBoldItalic, "FiraSans-BoldItalic"),
            (.openSansRegular, "OpenSansRoman-Regular"), (.openSansMedium, "OpenSansRoman-Medium"),
            (.openSansBold, "OpenSans-Bold")
        ]
        #expect(Set(FontFace.allCases) == Set(expected.map(\.0)))
        for (face, postScriptName) in expected {
            #expect(face.postScriptName == postScriptName)
            #expect(face.font(size: 16).fontName == postScriptName)
            let font = try #require(UIFont(name: postScriptName, size: 16))
            #expect(font.fontName == postScriptName)
        }
    }

    /// Font SwiftUI langsung harus menghasilkan ukuran teks yang sama dengan jalur `UIFont`, bukan system font.
    @MainActor
    @Test(arguments: FontFace.allCases)
    func swiftUIFontRendersLikeTheUIKitFont(face: FontFace) throws {
        try FontFace.registerFonts()
        let direct = renderedSize(face.swiftUIFont(size: 20))
        #expect(direct == renderedSize(Font(face.font(size: 20))))
        #expect(direct != renderedSize(.system(size: 20)))
    }

    @Test
    func chineseUsesRealFallbackGlyphsRatherThanMissingGlyphBoxes() throws {
        try FontFace.registerFonts()
        for face in FontFace.allCases {
            let text = NSAttributedString(string: "你好，世界", attributes: [.font: face.font(size: 16)])
            let line = CTLineCreateWithAttributedString(text as CFAttributedString)
            let runs = CTLineGetGlyphRuns(line) as? [CTRun] ?? []
            #expect(!runs.isEmpty, "\(face.rawValue)")
            for run in runs {
                var glyphs = Array(repeating: CGGlyph(0), count: CTRunGetGlyphCount(run))
                CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
                #expect(!glyphs.contains(0), "\(face.rawValue)")
            }
        }
    }
}

// MARK: - Helpers

private extension FontTests {
    @MainActor
    func renderedSize(_ font: Font) -> CGSize {
        let host = UIHostingController(rootView: Text("Halo, Lara Croft 123").font(font).fixedSize())
        return host.sizeThatFits(in: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
    }
}
