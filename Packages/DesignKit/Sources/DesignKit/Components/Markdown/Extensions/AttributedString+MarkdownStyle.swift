//
//  AttributedString+MarkdownStyle.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import SwiftUI

extension AttributedString {
    /// Mengubah style inline Markdown menjadi atribut SwiftUI: tebal = face bold, miring, coret, kode monospace
    /// berlatar, dan link bergaris bawah; warnanya mengikuti peran di `style`. `isBold` untuk teks yang seluruhnya
    /// tebal (heading, header tabel). Intent inline dilepas agar SwiftUI tidak menebalkan face bold dua kali.
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
                run.link == nil ? style.textColor(in: colors) : style.linkColor(in: colors)
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
        let isStrong = isBold || intent.contains(.stronglyEmphasized)
        let isItalic = intent.contains(.emphasized)
        if intent.contains(.code) {
            let font = Font.system(size: size, weight: isStrong ? .bold : .regular, design: .monospaced)
            return isItalic ? font.italic() : font
        }
        return style.face(isStrong: isStrong, isItalic: isItalic).swiftUIFont(size: size)
    }
}
