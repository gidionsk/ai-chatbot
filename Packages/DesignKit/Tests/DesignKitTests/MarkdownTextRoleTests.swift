//
//  MarkdownTextRoleTests.swift
//  DesignKitTests
//
//  Created by Wendra on 6/11/26.
//

import SwiftUI
import Testing

@testable import DesignKit

struct MarkdownTextRoleTests {
    private let colors = EnvironmentValues().designColors

    private func style(_ role: MarkdownTextRole) -> MarkdownTextStyle {
        MarkdownTextStyle(
            fontFace: .firaSansRegular, boldFontFace: .firaSansBold, italicFontFace: .firaSansItalic,
            boldItalicFontFace: .firaSansBoldItalic, role: role
        )
    }

    private func color(of run: AttributedString.Runs.Run) -> Color? {
        run[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self]
    }

    @Test
    func captionIsSmallCenteredWithSecondaryTextAndBrandLink() throws {
        let caption = style(.caption)
        let text = try AttributedString(markdown: "Baca [ketentuan](terms) ini.")
            .markdownStyled(size: caption.bodySize, style: caption, colors: colors)
        let link = try #require(text.runs.first { $0.link != nil })
        let plain = try #require(text.runs.first { $0.link == nil })
        #expect(color(of: link) == colors.colorsTextBrand)
        #expect(color(of: plain) == colors.colorsTextSecondary)
        #expect(link[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] == .single)
        #expect(caption.bodySize == FigmaSize.typographySizeDisplayTiny12.scaledToArtwork)
        #expect(caption.alignment == .center)
        #expect(caption.textAlignment == .center)
    }

    /// Jawaban bot tidak berubah oleh peran baru.
    @Test
    func bodyKeepsTheAnswerStyle() throws {
        let body = style(.body)
        let text = try AttributedString(markdown: "Lihat [kurs](https://example.com) ini.")
            .markdownStyled(size: body.bodySize, style: body, colors: colors)
        let link = try #require(text.runs.first { $0.link != nil })
        let plain = try #require(text.runs.first { $0.link == nil })
        #expect(color(of: link) == colors.colorsTextHyperlink)
        #expect(color(of: plain) == colors.colorsTextPrimaryDark)
        #expect(body.bodySize == FigmaSize.typographySizeDisplaySmall14.scaledToArtwork)
        #expect(body.alignment == .leading)
    }
}
