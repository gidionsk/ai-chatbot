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
    /// pengajuan yang sama bila hasil ACK belum pasti. Petakan kegagalan ke `ReferenceLetterSubmissionError`.
    /// successID diisi hanya jika host memiliki ID transaksi yang valid untuk chat gateway.
    func submit(
        _ request: ReferenceLetterRequest,
        pin: String
    ) async throws -> ReferenceLetterReceipt

    /// Dipanggil saat isi sheet PIN sudah hilang. Host menampilkan bottom sheet error-nya sendiri.
    func presentAcknowledgementError(_ error: Error)
}
