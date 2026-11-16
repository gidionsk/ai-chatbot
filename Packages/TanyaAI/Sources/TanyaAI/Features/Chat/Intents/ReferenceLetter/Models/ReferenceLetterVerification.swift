//
//  ReferenceLetterVerification.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Nilai responseCodeOTP yang dipakai host pada verifikasi sukses; bukan PIN yang diketik nasabah.
public struct ReferenceLetterVerification {
    public let responseCodeOTP: String

    public init(responseCodeOTP: String) {
        self.responseCodeOTP = responseCodeOTP
    }
}

/// Hanya dikembalikan host bila response_code ACK sukses. Copy dari data.title dan data.message BE.
public struct ReferenceLetterReceipt: Equatable {
    public let title: String
    public let message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}

/// Adapter host mengubah kode BE ke error ini (05516 PIN salah, 05005 terblokir, 05000/05006 verifikasi lain).
/// Pesan sudah dipilih host sesuai locale. Jangan menyertakan PIN/token dalam pesan.
public enum ReferenceLetterServiceError: Error {
    case invalidPIN(String)
    case blockedPIN(String)
    case verification(String)
    /// Penolakan ACK eksplisit oleh BE, berbeda dari timeout yang status transaksinya belum pasti.
    case rejected(String)
}
