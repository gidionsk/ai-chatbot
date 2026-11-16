//
//  ReferenceLetterService.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Inquiry milik project host: panggil service existing, decode BE, dan decrypt email sebelum mapping ke SDK.
/// SDK tidak memiliki route endpoint form ataupun implementasi jaringan.
@MainActor
public protocol ReferenceLetterService: AnyObject {
    func inquiry() async throws -> ReferenceLetterInquiry
}
