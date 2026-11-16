//
//  ReferenceLetterInquiry.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import DesignKit

/// Hasil inquiry yang sudah dipetakan host. `code` BE menjadi `OptionItem.id`, `value` menjadi `title`, dan
/// `description` rekening menjadi `subtitle`. Urutan BE dipertahankan. HTTP, response_code, dan dekripsi milik host.
public struct ReferenceLetterInquiry: Equatable {
    public let introduction: String
    public let purposes: [OptionItem]
    public let documentFormats: [OptionItem]
    public let sourceAccounts: [OptionItem]
    public let currencies: [OptionItem]
    public let languages: [OptionItem]
    public let address: String
    public let decryptedEmail: String
    /// Email terenkripsi asli, dikirim kembali pada ACK. Tidak pernah dipakai sebagai teks tampilan.
    public let encryptedEmail: String
    public let onlineSessionID: String

    public init(
        introduction: String,
        purposes: [OptionItem],
        documentFormats: [OptionItem],
        sourceAccounts: [OptionItem],
        currencies: [OptionItem],
        languages: [OptionItem] = [],
        address: String,
        decryptedEmail: String,
        encryptedEmail: String,
        onlineSessionID: String
    ) {
        self.introduction = introduction
        self.purposes = Self.unique(purposes)
        self.documentFormats = Self.unique(documentFormats)
        self.sourceAccounts = Self.unique(sourceAccounts)
        self.currencies = Self.unique(currencies)
        self.languages = Self.unique(languages)
        self.address = address
        self.decryptedEmail = decryptedEmail
        self.encryptedEmail = encryptedEmail
        self.onlineSessionID = onlineSessionID
    }
}

// MARK: - Helpers

private extension ReferenceLetterInquiry {
    static func unique(_ options: [OptionItem]) -> [OptionItem] {
        var seen: Set<String> = []
        return options.filter { !$0.id.isEmpty && seen.insert($0.id).inserted }
    }
}
