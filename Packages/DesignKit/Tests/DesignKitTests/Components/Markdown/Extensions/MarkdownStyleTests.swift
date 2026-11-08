//
//  MarkdownStyleTests.swift
//  DesignKitTests
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI
import Testing

@testable import DesignKit

/// Style inline menjadi atribut SwiftUI dari token; intent inline dilepas agar tidak ditebalkan dua kali.
struct MarkdownStyleTests {
    private let colors = DefaultColorConstants()
    private let style = MarkdownTextStyle(
        fontFace: .firaSansRegular, boldFontFace: .firaSansBold, italicFontFace: .firaSansItalic,
        boldItalicFontFace: .firaSansBoldItalic
    )

    @Test
    func linkKeepsItsURLAndGetsTheHyperlinkColorAndUnderline() throws {
        let run = try #require(styledRuns("Buka [kurs](https://ocbc.id/kurs)").last)
        #expect(run.link == URL(string: "https://ocbc.id/kurs"))
        #expect(run[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] == colors.colorsTextHyperlink)
        #expect(run[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] != nil)
    }

    @Test
    func strikeAndCodeGetTheirAttributesAndIntentsAreRemoved() throws {
        let runs = styledRuns("~~lama~~ `kode` **tebal**")
        #expect(runs.allSatisfy { $0.inlinePresentationIntent == nil })
        #expect(runs.first?[AttributeScopes.SwiftUIAttributes.StrikethroughStyleAttribute.self] != nil)
        let code = try #require(
            runs.first { $0[AttributeScopes.SwiftUIAttributes.BackgroundColorAttribute.self] != nil })
        #expect(String(code.characters) == "kode")
    }

    @Test
    func plainTextUsesTheBodyColorWithoutDecoration() throws {
        let run = try #require(styledRuns("teks biasa").first)
        #expect(run[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] == colors.colorsTextPrimaryDark)
        #expect(run[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] == nil)
    }

    @Test
    func italicAndBoldItalicUseTheirOwnFaces() throws {
        let italic = try #require(styledRuns("*miring*").first)
        let boldItalic = try #require(styledRuns("***keduanya***").first)
        #expect(italic[fontAttribute] == FontFace.firaSansItalic.swiftUIFont(size: style.bodySize))
        #expect(boldItalic[fontAttribute] == FontFace.firaSansBoldItalic.swiftUIFont(size: style.bodySize))
    }

    @Test
    func taskMarkerReplacesTheBulletButKeepsTheNumber() {
        let box = MarkdownSyntax.listMarker(ordinal: 1, isOrdered: false, depth: 0, task: .done)
        #expect(box.unicodeScalars.first == "\u{2611}")
        #expect(MarkdownSyntax.listMarker(ordinal: 3, isOrdered: true, depth: 0, task: .open).hasPrefix("3. "))
    }

    @Test
    func boldCodeKeepsMonospaceAndWeight() throws {
        let run = try #require(styledRuns("**`kode`**").first)
        #expect(run[fontAttribute] == .system(size: style.bodySize, weight: .bold, design: .monospaced))
    }

    @Test(arguments: [(0, "•"), (1, "◦"), (2, "▪\u{FE0E}"), (3, "•")])
    func bulletChangesPerDepth(depth: Int, marker: String) {
        #expect(MarkdownSyntax.listMarker(ordinal: 1, isOrdered: false, depth: depth) == marker)
        #expect(MarkdownSyntax.listMarker(ordinal: 7, isOrdered: true, depth: depth) == "7.")
    }
}

// MARK: - Helpers

private extension MarkdownStyleTests {
    var fontAttribute: AttributeScopes.SwiftUIAttributes.FontAttribute.Type {
        AttributeScopes.SwiftUIAttributes.FontAttribute.self
    }

    func styledRuns(_ markdown: String) -> [AttributedSubstring] {
        guard case .paragraph(let text) = MarkdownDocument(markdown).blocks.first else { return [] }
        let styled = text.markdownStyled(size: style.bodySize, style: style, colors: colors)
        return styled.runs.map { styled[$0.range] }
    }
}
