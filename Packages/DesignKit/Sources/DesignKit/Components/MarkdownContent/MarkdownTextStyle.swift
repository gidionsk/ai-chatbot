//
//  MarkdownTextStyle.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import CoreGraphics

/// Font Markdown milik pemakai dan kedalaman list saat ini (penanda bullet berganti per level).
struct MarkdownTextStyle {
    let fontFace: FontFace
    let boldFontFace: FontFace
    let italicFontFace: FontFace
    let boldItalicFontFace: FontFace
    var listDepth = Int.zero

    var bodySize: CGFloat { FigmaSize.typographySizeDisplaySmall14.scaledToArtwork }
    var codeSize: CGFloat { FigmaSize.typographySizeDisplayTiny12.scaledToArtwork }

    /// `#` = heading kecil 20, `##` = 16, `###` ke bawah = ukuran isi; semuanya tebal.
    func headingSize(level: Int) -> CGFloat {
        switch level {
        case MarkdownSyntax.titleLevel:
            return FigmaSize.typographySizeHeadingSmall20.scaledToArtwork
        case MarkdownSyntax.sectionLevel:
            return FigmaSize.typographySizeDisplayNormal16.scaledToArtwork
        default:
            return bodySize
        }
    }

    func face(isStrong: Bool, isItalic: Bool) -> FontFace {
        switch (isStrong, isItalic) {
        case (true, true):
            return boldItalicFontFace
        case (true, false):
            return boldFontFace
        case (false, true):
            return italicFontFace
        case (false, false):
            return fontFace
        }
    }

    /// Style untuk isi item list satu level lebih dalam.
    func nested() -> MarkdownTextStyle {
        var style = self
        style.listDepth += MarkdownSyntax.nestingStep
        return style
    }
}
