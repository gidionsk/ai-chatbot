//
//  ReferenceLetterService.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Diimplementasikan adapter host memakai service Byon existing. GET inquiry, cek response_code, mapping model,
/// dan dekripsi email selesai di host sebelum data dikembalikan. Tidak memakai transport chat-gateway.
@MainActor
public protocol ReferenceLetterService: AnyObject {
    func inquiry() async throws -> ReferenceLetterInquiry
    /// Host membuat otpCode melalui token/PIN service existing beserta sequenceNumber/appliNumber/challengeCode.
    /// Plain PIN hanya argumen panggilan ini; tidak disimpan dalam draft, request ACK, atau history.
    func verify(pin: String) async throws -> ReferenceLetterVerification
    /// Dipanggil hanya sesudah verify sukses. Tidak di-retry otomatis.
    func acknowledge(_ request: ReferenceLetterRequest) async throws -> ReferenceLetterReceipt
}
