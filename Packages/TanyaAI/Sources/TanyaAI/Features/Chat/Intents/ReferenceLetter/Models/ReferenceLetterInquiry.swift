//
//  ReferenceLetterInquiry.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Data inquiry yang sudah dipetakan host. HTTP, decoding dan dekripsi email milik project host.
/// Tampilan memetakan FormOption ke komponen pilihan; seleksi dan validasi milik mesin form bersama.
public struct ReferenceLetterInquiry: Equatable {
    public let introduction: String
    public let purposes: [FormOption]
    public let documentFormats: [FormOption]
    public let sourceAccounts: [FormOption]
    public let currencies: [FormOption]
    public let languages: [FormOption]
    public let address: String
    public let decryptedEmail: String
    /// Email terenkripsi asli, disimpan untuk dikirim kembali ke host.
    /// Tidak pernah dipakai sebagai teks tampilan.
    public let encryptedEmail: String
    public let onlineSessionID: String

    public init(
        introduction: String,
        purposes: [FormOption],
        documentFormats: [FormOption],
        sourceAccounts: [FormOption],
        currencies: [FormOption],
        languages: [FormOption] = [],
        address: String,
        decryptedEmail: String,
        encryptedEmail: String,
        onlineSessionID: String
    ) {
        self.introduction = introduction
        self.purposes = purposes
        self.documentFormats = documentFormats
        self.sourceAccounts = sourceAccounts
        self.currencies = currencies
        self.languages = languages
        self.address = address
        self.decryptedEmail = decryptedEmail
        self.encryptedEmail = encryptedEmail
        self.onlineSessionID = onlineSessionID
    }
}
