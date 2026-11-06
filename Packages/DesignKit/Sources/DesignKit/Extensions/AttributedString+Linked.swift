//
//  AttributedString+Linked.swift
//  DesignKit
//
//  Created by Wendra on 6/11/26.
//

import SwiftUI

extension AttributedString {
    /// Teks dari Markdown dengan link berwarna `linkColor` dan bergaris bawah; bagian lain mengikuti style `Text`.
    /// Markdown yang gagal dibaca tetap tampil sebagai teks biasa.
    static func linked(markdown: String, linkColor: Color) -> AttributedString {
        let parsed = (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
        var styled = parsed
        for run in parsed.runs where run.link != nil {
            var container = AttributeContainer()
            container[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] = linkColor
            container[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] = .single
            styled[run.range].mergeAttributes(container)
        }
        return styled
    }
}
