//
//  ReferenceLetterDemoData.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

/// Fixture lokal untuk tampilan. Bukan definisi intent produksi atau kontrak endpoint.
enum ReferenceLetterDemoData {
    static let title = "Pesan Surat Referensi"
    static let confirm = "Kirim"
    static let cancel = "Batalkan"
    static let choose = "Pilih"
    static let close = "Tutup"
    static let validated = "Data form sudah valid (demo)."
    static let initialEmbassy = "Kedutaan Amerika Serikat"

    static let inquiry = ReferenceLetterInquiry(
        introduction: """
            Hi Lara, untuk melanjutkan proses ini silakan mengisi form di bawah ini dengan baik dan benar.

            Untuk saat ini kami hanya bisa menyediakan versi dalam bentuk PDF & hardcopy.
            • Untuk versi hardcopy akan dikenakan biaya IDR 50.000 ke rekening sumber dana utama kamu.
            • Akan diproses selama 3–7 hari kerja.
            """,
        purposes: [
            FormOption(code: "visa", title: "Pengajuan VISA"),
            FormOption(code: "education", title: "Keperluan pendidikan"),
            FormOption(code: "other", title: "Lainnya")
        ],
        documentFormats: [
            FormOption(code: "SOFTCOPY", title: "Softcopy"),
            FormOption(code: "HARDCOPY", title: "Hardcopy")
        ],
        sourceAccounts: [
            FormOption(code: "account-1", title: "Tanda 360 - 2345 5678 2386", subtitle: "IDR 1.000.000"),
            FormOption(code: "account-2", title: "Tanda 360 Max - 2345 5678 2387", subtitle: "IDR 5.000.000"),
            FormOption(code: "account-3", title: "Tanda 360 Duo - 2345 5678 2388", subtitle: "IDR 2.500.000")
        ],
        currencies: [
            FormOption(code: "IDR", title: "IDR"),
            FormOption(code: "USD", title: "USD")
        ],
        address: "Jl. BSD Grand Boulevard No. 1, Tangerang Selatan",
        decryptedEmail: "samara@mail.com",
        encryptedEmail: "dummy-encrypted-email",
        onlineSessionID: "dummy-reference-letter-session"
    )
}
