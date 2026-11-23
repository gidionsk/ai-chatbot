//
//  ReferenceLetterForm.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

import Combine
import DesignKit
import Foundation

/// Draft milik satu pesan. Ketikan hanya diamati oleh baris form yang bersangkutan.
@MainActor
final class ReferenceLetterForm: ObservableObject {
    @Published var draft = IntentFormState<ReferenceLetterFieldID>(
        rules: IntentFormRules(fields: { _ in [] }, fieldsToReset: { _ in [] })
    ) {
        didSet {
            if case .form = layout { updateLayout(draftLayout) }
        }
    }
    @Published private(set) var inquiry: ReferenceLetterInquiry?
    @Published private(set) var receipt: ReferenceLetterReceipt?
    @Published private(set) var pinError: ReferenceLetterSubmissionError?
    private(set) var layout = ReferenceLetterLayout.loading
    private(set) var introduction: MarkdownDocument?
    private(set) var acknowledgement: MarkdownDocument?
    private let onLayoutChange: (ReferenceLetterForm, ReferenceLetterLayout) -> Void
    private var isLoading = false
    private let service: any ReferenceLetterService

    init(
        service: any ReferenceLetterService,
        onLayoutChange: @escaping (ReferenceLetterForm, ReferenceLetterLayout) -> Void = { _, _ in }
    ) {
        self.service = service
        self.onLayoutChange = onLayoutChange
    }

    func load() async {
        guard !isLoading, layout == .loading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let data = try await service.inquiry()
            guard !Task.isCancelled, layout == .loading else { return }
            introduction = data.introduction.isEmpty ? nil : MarkdownDocument(data.introduction)
            draft = IntentFormState(rules: ReferenceLetterFieldID.rules(inquiry: data))
            inquiry = data
            updateLayout(draftLayout)
        } catch {
            if !Task.isCancelled, layout == .loading { updateLayout(.hidden) }
        }
    }

    func cancel() {
        guard case .form = layout else { return }
        updateLayout(.cancelled)
        discardInquiry()
    }

    func clearSubmissionError() {
        pinError = nil
    }

    func submit(pin: String) async throws -> ReferenceLetterReceipt? {
        guard ReferenceLetterPIN.isValid(pin),
            case .form = layout,
            let inquiry,
            draft.validate(),
            let request = ReferenceLetterRequest(draft: draft, inquiry: inquiry)
        else { return nil }
        clearSubmissionError()
        do {
            let result = try await service.submit(request, pin: pin)
            acknowledgement = result.message.isEmpty ? nil : MarkdownDocument(result.message)
            receipt = result
            updateLayout(.submitted)
            discardInquiry()
            return result
        } catch let error as ReferenceLetterSubmissionError {
            if case .pinVerification = error {
                pinError = error
                return nil
            }
            throw error
        }
    }

    func presentAcknowledgementError(_ error: Error) {
        service.presentAcknowledgementError(error)
    }
}

private extension ReferenceLetterForm {
    var draftLayout: ReferenceLetterLayout {
        var selections: [ReferenceLetterFieldID: [String]] = [:]
        for field in draft.visibleFields {
            guard let codes = draft.value(for: field.id)?.selectedCodes, !codes.isEmpty else { continue }
            // Daftar opsi berasal dari inquiry yang sama; kode menandai perubahan teks ringkasan.
            selections[field.id] = codes
        }
        return .form(
            fields: draft.visibleFields.map(\.id),
            invalid: draft.invalidFieldIDs,
            selections: selections
        )
    }

    func updateLayout(_ nextLayout: ReferenceLetterLayout) {
        guard layout != nextLayout else { return }
        layout = nextLayout
        onLayoutChange(self, nextLayout)
    }

    func discardInquiry() {
        introduction = nil
        inquiry = nil
        draft = IntentFormState(rules: IntentFormRules(fields: { _ in [] }, fieldsToReset: { _ in [] }))
    }
}
