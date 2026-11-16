//
//  ReferenceLetterSubmissionService.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

/// Capability submit opsional, terpisah dari inquiry agar form dapat diintegrasikan bertahap.
/// Host memakai flow PIN existing beserta verifikasi BE-nya. SDK tidak menerima angka PIN.
@MainActor
public protocol ReferenceLetterSubmissionService: AnyObject {
    /// Membuka flow PIN host dan menunggu verifikasi sukses. Nil = nasabah batal.
    /// Retry PIN salah, PIN terblokir, dan lifecycle presentasi tetap ditangani coordinator host.
    func authorize() async throws -> ReferenceLetterAuthorization?
    /// Dipanggil hanya setelah authorize sukses. Tidak di-retry otomatis.
    func acknowledge(
        _ request: ReferenceLetterRequest,
        authorization: ReferenceLetterAuthorization
    ) async throws -> ReferenceLetterReceipt
}
