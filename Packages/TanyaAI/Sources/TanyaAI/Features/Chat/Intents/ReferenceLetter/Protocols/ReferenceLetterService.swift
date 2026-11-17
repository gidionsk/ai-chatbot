//
//  ReferenceLetterService.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Kontrak inquiry yang diimplementasikan host menggunakan service existing.
/// Host mengembalikan model data TanyaAI; decoding dan dekripsi email selesai sebelum data diteruskan ke SDK.
@MainActor
public protocol ReferenceLetterService: AnyObject {
    func inquiry() async throws -> ReferenceLetterInquiry
}
