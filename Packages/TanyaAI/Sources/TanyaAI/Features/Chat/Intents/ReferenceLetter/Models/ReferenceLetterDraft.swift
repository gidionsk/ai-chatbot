//
//  ReferenceLetterDraft.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Nilai form milik caller, disimpan di luar sel table. Semua pilihan menyimpan kode BE, bukan label tampilan.
/// Dipetakan ke request ACK setelah validasi; email/alamat bukan input draft yang bisa diedit.
public struct ReferenceLetterDraft: Equatable {
    public var purposeCode: String?
    public var documentFormatCode: String?
    public var destination = String()
    public var accountCodes: [String] = []
    public var currencyCode: String?
    public var languageCode: String?
    public var isBalanceShown = true
    public var isInvestmentShown = false

    public init() {}

    /// Hanya purpose dan format memiliki default index 0 menurut catatan BE. Daftar kosong tetap nil.
    public init(inquiry: ReferenceLetterInquiry) {
        purposeCode = inquiry.purposes.first?.id
        documentFormatCode = inquiry.documentFormats.first?.id
    }
}
