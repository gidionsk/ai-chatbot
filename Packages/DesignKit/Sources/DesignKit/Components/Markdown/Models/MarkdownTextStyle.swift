//
//  MarkdownTextStyle.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

/// Peran teks Markdown dan kedalaman list saat ini (penanda bullet berganti per level). Face selalu Fira Sans;
/// tebal dan miring memilih face-nya sendiri, bukan ditebalkan sistem.
struct MarkdownTextStyle {
    var listDepth = Int.zero
    var role = MarkdownTextRole.body

    var bodySize: CGFloat {
        guard role == .caption else { return FigmaSize.typographySizeDisplaySmall14.scaledToArtwork }
        return FigmaSize.typographySizeDisplayTiny12.scaledToArtwork
    }

    var alignment: Alignment { role == .caption ? .center : .leading }
    var textAlignment: TextAlignment { role == .caption ? .center : .leading }
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

    func textColor(in colors: any FigmaColorProtocol) -> Color {
        role == .caption ? colors.colorsTextSecondary : colors.colorsTextPrimaryDark
    }

    func linkColor(in colors: any FigmaColorProtocol) -> Color {
        role == .caption ? colors.colorsTextBrand : colors.colorsTextHyperlink
    }

    /// Font isi tanpa tebal atau miring, mis. penanda list dan teks alt gambar.
    var bodyFont: Font { face(isStrong: false, isItalic: false).swiftUIFont(size: bodySize) }

    func face(isStrong: Bool, isItalic: Bool) -> FontFace {
        switch (isStrong, isItalic) {
        case (true, true):
            return .firaSansBoldItalic
        case (true, false):
            return .firaSansBold
        case (false, true):
            return .firaSansItalic
        case (false, false):
            return .firaSansRegular
        }
    }

    /// Style untuk isi item list satu level lebih dalam.
    func nested() -> MarkdownTextStyle {
        var style = self
        style.listDepth += MarkdownSyntax.nestingStep
        return style
    }
}
