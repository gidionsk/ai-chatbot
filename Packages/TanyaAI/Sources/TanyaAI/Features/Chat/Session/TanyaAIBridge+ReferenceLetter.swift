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

    func isReferenceLetterEnabled(for item: ChatListItem) -> Bool {
        guard case .message(.message(let message), _) = item, message.intent == .referenceLetter,
            message.author == .assistant, message.status == .active
        else { return false }
        return services.referenceLetter != nil
    }

    func prepareReferenceLetter(for message: ChatMessage) {
        guard message.intent == .referenceLetter, message.author == .assistant,
            message.status == .active, message.successID == nil, referenceLetters[message.id] == nil,
            !messages.contains(where: { $0.id == message.id }), let service = services.referenceLetter
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

    func isSubmittingReferenceLetter(messageID: String) -> Bool {
        guard let form = referenceLetters[messageID] else { return false }
        return submittingReferenceLetters.contains(ObjectIdentifier(form))
    }

    func submitReferenceLetter(pin: String, messageID: String) async throws -> Bool {
        guard isReady, let form = pendingReferenceLetter(messageID: messageID) else { return false }
        let formIdentity = ObjectIdentifier(form)
        guard !submittingReferenceLetters.contains(formIdentity) else { return false }
        submittingReferenceLetters.insert(formIdentity)
        defer { submittingReferenceLetters.remove(formIdentity) }

        let receipt: ReferenceLetterReceipt?
        do {
            receipt = try await form.submit(pin: pin)
        } catch {
            guard pendingReferenceLetter(messageID: messageID) === form else { return false }
            throw error
        }
        guard let receipt, pendingReferenceLetter(messageID: messageID) === form else { return false }
        if let successID = receipt.successID, !successID.isEmpty {
            // ACK sudah berhasil. Gagal memasang receipt gateway tidak mengulang pengajuan.
            Task {
                guard pendingReferenceLetter(messageID: messageID) === form else { return }
                try? await attachSuccessID(successID, toMessageID: messageID)
            }
        }
        return true
    }
}

private extension TanyaAIBridge {
    func pendingReferenceLetter(messageID: String) -> ReferenceLetterForm? {
        guard let form = referenceLetters[messageID],
            messages.contains(where: { $0.id == messageID && $0.status == .active && $0.successID == nil })
        else { return nil }
        return form
    }
}
