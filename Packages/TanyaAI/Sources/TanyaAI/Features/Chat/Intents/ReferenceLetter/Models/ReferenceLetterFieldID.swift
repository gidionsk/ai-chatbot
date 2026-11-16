//
//  ReferenceLetterFieldID.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Identitas teknis field, bukan teks tampilan. Dipakai caller untuk sheet dan error per field.
public enum ReferenceLetterFieldID: String, CaseIterable, Hashable {
    case purpose
    case documentFormat
    case destination
    case accounts
    case currency
    case language
}

/// Kode kontrak inquiry; jangan menilai format dari label yang dapat diterjemahkan BE.
public enum ReferenceLetterDocumentFormat: String {
    case softcopy = "SOFTCOPY"
    case hardcopy = "HARDCOPY"
}
