//
//  TanyaAIBridge+Form.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import Foundation

extension TanyaAIBridge {
    /// Dipanggil saat event terminal datang, bukan dari body/sel. Replay mempertahankan instance yang sama.
    func registerForm(for message: ChatMessage, isHistory: Bool) {
        guard message.author == .assistant, message.intent == .referenceLetter, message.status == .active,
            referenceLetters[message.id] == nil, let service = services.referenceLetter
        else { return }
        let session = ReferenceLetterSession(
            service: service,
            submission: services.referenceLetterSubmission,
            isHistory: isHistory
        )
        referenceLetters[message.id] = session
        if !isHistory { Task { await session.load() } }
    }

    /// Percakapan baru/logout tidak boleh menerima hasil request form percakapan sebelumnya.
    func resetForms() {
        referenceLetters.values.forEach { $0.invalidate() }
        referenceLetters = [:]
    }
}
