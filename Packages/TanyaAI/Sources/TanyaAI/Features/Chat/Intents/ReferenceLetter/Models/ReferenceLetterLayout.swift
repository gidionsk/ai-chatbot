//
//  ReferenceLetterLayout.swift
//  TanyaAI
//
//  Created by Wendra on 22/11/26.
//

/// Perubahan yang mengubah tinggi baris chat, tanpa memasukkan teks yang sedang diketik.
enum ReferenceLetterLayout: Equatable {
    case loading
    case hidden
    case form(fields: [ReferenceLetterFieldID], invalid: Set<ReferenceLetterFieldID>)
    case submitted
    case cancelled
}
