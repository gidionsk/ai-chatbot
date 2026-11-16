//
//  ReferenceLetterSession.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import Combine
import DesignKit
import Foundation

/// State inquiry dan draft per message_id, dimiliki bridge di luar sel table.
@MainActor
final class ReferenceLetterSession: ObservableObject {
    @Published private(set) var phase = FormSubmissionPhase.idle
    @Published private(set) var inquiry: ReferenceLetterInquiry?
    @Published var draft = ReferenceLetterDraft()
    @Published private(set) var invalidFields: Set<ReferenceLetterFieldID> = []
    private var generation = UUID()
    private let service: ReferenceLetterService

    init(service: ReferenceLetterService, isHistory: Bool = false) {
        self.service = service
        phase = isHistory ? .history : .idle
    }

    func load() async {
        guard phase == .idle || phase == .loadFailed else { return }
        phase = .loading
        let current = generation
        do {
            let result = try await service.inquiry()
            guard current == generation, !Task.isCancelled else { return }
            guard !result.onlineSessionID.isEmpty else {
                phase = .loadFailed
                return
            }
            inquiry = result
            draft = ReferenceLetterDraft(inquiry: result)
            phase = .editing
        } catch {
            guard current == generation else { return }
            phase = .loadFailed
        }
    }

    func clearResolvedErrors() {
        guard let inquiry else { return }
        invalidFields.formIntersection(draft.invalidFields(in: inquiry))
    }

    func cancel() { invalidate() }

    func leaveScreen() {
        if phase == .loading { invalidate() }
    }

    func invalidate() {
        generation = UUID()
        phase = .cancelled
    }
}
