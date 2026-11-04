//
//  TanyaAIUseCase+Chat.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 30/10/26.
//

import Foundation
import TanyaAI

/// UseCase menjadi transport TanyaAI: setiap fungsi memanggil API lewat `chatService`. Callback service
/// dibungkus continuation menjadi async; urutan, retry, dan decode milik TanyaAI. Sama dengan kode Byon.
extension TanyaAIUseCase: TanyaAIChatTransport {
    func initialize() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            chatService.initialize(
                onSuccess: { continuation.resume(returning: $0) },
                onFailed: { continuation.resume(throwing: $0) }
            )
        }
    }

    func history(conversationID: String, before: String?, limit: Int) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            chatService.history(
                conversationID: conversationID, before: before, limit: limit,
                onSuccess: { continuation.resume(returning: $0) },
                onFailed: { continuation.resume(throwing: $0) }
            )
        }
    }

    func sendMessage(conversationID: String, clientMessageID: String, text: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            chatService.sendMessage(
                conversationID: conversationID, clientMessageID: clientMessageID, text: text,
                onSuccess: { continuation.resume(returning: $0) },
                onFailed: { continuation.resume(throwing: $0) }
            )
        }
    }

    func cancelTurn(conversationID: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            chatService.cancelTurn(
                conversationID: conversationID,
                onSuccess: { continuation.resume(returning: $0) },
                onFailed: { continuation.resume(throwing: $0) }
            )
        }
    }

    func events(conversationID: String, lastEventID: String?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let request = chatService.events(
                conversationID: conversationID, lastEventID: lastEventID,
                onLine: { continuation.yield($0) },
                onComplete: { continuation.finish(throwing: $0) }
            )
            // Wajib: TanyaAI menutup stream saat halaman ditutup atau sesi habis.
            continuation.onTermination = { _ in request.cancel() }
        }
    }
}
