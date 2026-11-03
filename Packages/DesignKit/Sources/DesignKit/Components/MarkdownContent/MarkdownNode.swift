//
//  MarkdownNode.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

import Foundation

/// Simpul pohon sementara saat parsing: satu `PresentationIntent.IntentType` beserta anak dan teksnya.
/// Hanya simpul terdalam (paragraf, heading, code, sel tabel) yang punya teks.
struct MarkdownNode {
    let kind: PresentationIntent.Kind
    let identity: Int
    var children: [MarkdownNode] = []
    var text = AttributedString()
}
