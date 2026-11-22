//
//  ReferenceLetterDocumentFormat.swift
//  TanyaAI
//
//  Created by Wendra on 22/11/26.
//

/// Cara pengiriman yang dikenali form berdasarkan kode inquiry.
enum ReferenceLetterDocumentFormat: String {
    case softcopy
    case hardcopy

    init?(code: String) {
        self.init(rawValue: code.lowercased())
    }
}
