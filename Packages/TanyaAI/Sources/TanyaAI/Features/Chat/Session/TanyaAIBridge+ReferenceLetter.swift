//
//  TanyaAIBridge+ReferenceLetter.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

extension TanyaAIBridge {
    func referenceLetter(for item: ChatListItem) -> ReferenceLetterForm? {
        guard case .message(.message(let message), _) = item else { return nil }
        return referenceLetters[message.id]
    }

    func prepareReferenceLetter(for message: ChatMessage) {
        guard let service = services.referenceLetter, message.intent == .referenceLetter, message.author == .assistant,
            message.status == .active, message.successID == nil, referenceLetters[message.id] == nil,
            !messages.contains(where: { $0.id == message.id })
        else { return }
        let form = ReferenceLetterForm(service: service) { [weak self] sender, layout in
            guard let self, self.referenceLetters[message.id] === sender else { return }
            self.referenceLetterLayouts[.message(message.id)] = layout
        }
        referenceLetters[message.id] = form
        referenceLetterLayouts[.message(message.id)] = .loading
        Task { await form.load() }
    }

    func resetReferenceLetters() {
        referenceLetters.removeAll()
        referenceLetterLayouts.removeAll()
    }

    func submitReferenceLetter(pin: String, messageID: String) async throws -> Bool {
        guard isReady, !isSubmittingReferenceLetter,
            let form = referenceLetters[messageID],
            messages.contains(where: { $0.id == messageID && $0.status == .active && $0.successID == nil })
        else { return false }
        isSubmittingReferenceLetter = true
        defer { isSubmittingReferenceLetter = false }
        let receipt: ReferenceLetterReceipt?
        do {
            receipt = try await form.submit(pin: pin)
        } catch {
            guard referenceLetters[messageID] === form else { return false }
            throw error
        }
        guard let receipt, referenceLetters[messageID] === form else { return false }
        if let successID = receipt.successID, !successID.isEmpty {
            // ACK sudah berhasil. Gagal memasang receipt gateway tidak mengulang pengajuan.
            Task {
                guard referenceLetters[messageID] === form else { return }
                try? await attachSuccessID(successID, toMessageID: messageID)
            }
        }
        return true
    }
}
