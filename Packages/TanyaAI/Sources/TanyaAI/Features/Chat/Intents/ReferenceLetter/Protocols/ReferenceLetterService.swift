//
//  ReferenceLetterService.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Kontrak Surat Referensi yang diimplementasikan host menggunakan service existing.
/// Host mengembalikan model data TanyaAI; decoding dan dekripsi email selesai sebelum data diteruskan ke SDK.
@MainActor
public protocol ReferenceLetterService: AnyObject {
    func inquiry() async throws -> ReferenceLetterInquiry

    /// Host memverifikasi PIN memakai mekanisme existing, lalu memanggil ACK hanya setelah sukses.
    /// PIN diteruskan sekali dan tidak boleh disimpan atau dicatat. Gunakan onlineSessionID untuk mengenali
    /// pengajuan yang sama bila hasil ACK belum pasti. LocalizedError boleh membawa pesan aman untuk nasabah.
    /// successID diisi hanya jika host memiliki ID transaksi yang valid untuk chat gateway.
    func submit(
        _ request: ReferenceLetterRequest,
        pin: String
    ) async throws -> ReferenceLetterReceipt
}

/// Kartu hasil ACK dan ID bukti transaksi bila disediakan host.
public struct ReferenceLetterReceipt {
    public let title: String
    public let message: String
    public let successID: String?

    public init(title: String, message: String, successID: String? = nil) {
        self.title = title
        self.message = message
        self.successID = successID
    }
}
