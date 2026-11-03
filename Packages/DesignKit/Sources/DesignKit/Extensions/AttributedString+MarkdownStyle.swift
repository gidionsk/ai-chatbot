//
//  AttributedString+MarkdownStyle.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

extension AttributedString {
    /// Mengubah style inline Markdown menjadi atribut SwiftUI: tebal = face bold, miring, coret, kode monospace
    /// berlatar, dan link berwarna hyperlink bergaris bawah. `isBold` untuk teks yang seluruhnya tebal (heading,
    /// header tabel). Intent inline dilepas agar SwiftUI tidak menebalkan face bold dua kali.
    /// TODO: Open Sans belum punya face italic; miring masih sintetis dari sistem.
    func markdownStyled(
        size: CGFloat, isBold: Bool = false, style: MarkdownTextStyle, colors: any FigmaColorProtocol
    ) -> AttributedString {
        var styled = self
        for run in runs {
            let intent = run.inlinePresentationIntent ?? []
            var container = AttributeContainer()
            container[AttributeScopes.SwiftUIAttributes.FontAttribute.self] = font(
                for: intent, size: size, isBold: isBold, style: style
            )
            container[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] =
                run.link == nil ? colors.colorsTextPrimaryDark : colors.colorsTextHyperlink
            if intent.contains(.strikethrough) {
                container[AttributeScopes.SwiftUIAttributes.StrikethroughStyleAttribute.self] = .single
            }
            if run.link != nil {
                container[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] = .single
            }
            if intent.contains(.code) {
                container[AttributeScopes.SwiftUIAttributes.BackgroundColorAttribute.self] =
                    colors.colorsSurfaceSelected
            }
            styled[run.range].mergeAttributes(container)
            styled[run.range].inlinePresentationIntent = nil
        }
        return styled
    }
}

// MARK: - Helpers

private extension AttributedString {
    func font(for intent: InlinePresentationIntent, size: CGFloat, isBold: Bool, style: MarkdownTextStyle) -> Font {
        if intent.contains(.code) {
            return .system(size: size, design: .monospaced)
        }
        let face = isBold || intent.contains(.stronglyEmphasized) ? style.boldFontFace : style.fontFace
        let font = face.swiftUIFont(size: size)
        return intent.contains(.emphasized) ? font.italic() : font
    }
}
