//
//  MarkdownParser.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import Foundation

/// Mengubah Markdown menjadi blok. Parser Apple memberi setiap run teks jalur `PresentationIntent` (dari blok
/// terdalam ke terluar, masing-masing dengan `identity` unik); run berurutan dengan jalur sama disatukan menjadi
/// pohon, lalu pohon dipetakan ke `MarkdownBlock`.
enum MarkdownParser {
    /// Teks yang gagal di-parse tetap tampil sebagai satu paragraf polos.
    static func blocks(from markdown: String) -> [MarkdownBlock] {
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .full, failurePolicy: .returnPartiallyParsedIfPossible
        )
        guard let parsed = try? AttributedString(markdown: markdown, options: options) else {
            return [.paragraph(AttributedString(markdown))]
        }
        return tree(from: parsed).flatMap(blocks(from:))
    }

    static func tree(from text: AttributedString) -> [MarkdownNode] {
        var roots: [MarkdownNode] = []
        for run in text.runs {
            // Struktur blok sudah ada di pohon; teks cukup membawa atribut inline.
            var slice = AttributedString(text[run.range])
            slice.presentationIntent = nil
            if let intent = run.presentationIntent {
                insert(slice, path: Array(intent.components.reversed())[...], into: &roots)
            } else {
                appendPlain(slice, to: &roots)
            }
        }
        return roots
    }
}

// MARK: - Tree

private extension MarkdownParser {
    /// Identitas paragraf untuk run tanpa blok (jarang); tidak bentrok dengan identitas parser yang positif.
    static let plainIdentity = Int.min

    static func appendPlain(_ text: AttributedString, to nodes: inout [MarkdownNode]) {
        if nodes.last?.identity != plainIdentity {
            nodes.append(MarkdownNode(kind: .paragraph, identity: plainIdentity))
        }
        nodes[nodes.index(before: nodes.endIndex)].text.append(text)
    }

    /// `path` dari blok terluar. Simpul dipakai ulang bila `identity` sama dengan simpul terakhir di level itu.
    static func insert(
        _ text: AttributedString, path: ArraySlice<PresentationIntent.IntentType>, into nodes: inout [MarkdownNode]
    ) {
        guard let intent = path.first else { return }
        if nodes.last?.identity != intent.identity {
            nodes.append(MarkdownNode(kind: intent.kind, identity: intent.identity))
        }
        let index = nodes.index(before: nodes.endIndex)
        if path.dropFirst().isEmpty {
            nodes[index].text.append(text)
        } else {
            insert(text, path: path.dropFirst(), into: &nodes[index].children)
        }
    }
}
