//
//  ReferenceLetterForm.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

import Combine
import Foundation

/// Draft milik satu pesan. Ketikan hanya diamati oleh baris form yang bersangkutan.
@MainActor
final class ReferenceLetterForm: ObservableObject {
    @Published var draft = IntentFormState<ReferenceLetterFieldID>(
        rules: IntentFormRules(fields: { _ in [] }, fieldsToReset: { _ in [] })
    )
    @Published private(set) var inquiry: ReferenceLetterInquiry?
    @Published private(set) var receipt: ReferenceLetterReceipt?
    @Published private(set) var isCancelled = false
    @Published private(set) var isInquiryFailed = false
    @Published private(set) var submissionError: String?
    @Published private(set) var isSubmissionFailed = false
    private var isLoading = false
    private let service: any ReferenceLetterService

    init(service: any ReferenceLetterService) {
        self.service = service
    }

    func load() async {
        guard !isLoading, inquiry == nil else { return }
        isLoading = true
        isInquiryFailed = false
        defer { isLoading = false }
        do {
            let data = try await service.inquiry()
            guard !Task.isCancelled else { return }
            draft = IntentFormState(rules: ReferenceLetterFieldID.rules(inquiry: data))
            inquiry = data
        } catch {
            isInquiryFailed = !Task.isCancelled
        }
    }

    func cancel() {
        isCancelled = true
        discardInquiry()
    }

    func clearSubmissionError() {
        guard isSubmissionFailed else { return }
        isSubmissionFailed = false
        submissionError = nil
    }

    func submit(pin: String) async -> ReferenceLetterReceipt? {
        guard pin.count == ChatWire.referenceLetterPinLength, !isCancelled, receipt == nil, let inquiry,
            draft.validate(),
            let request = ReferenceLetterRequest(draft: draft, inquiry: inquiry)
        else { return nil }
        clearSubmissionError()
        do {
            let result = try await service.submit(request, pin: pin)
            receipt = result
            discardInquiry()
            return result
        } catch {
            // Hanya pesan yang sengaja dipetakan host untuk ditampilkan yang diteruskan ke UI.
            submissionError = (error as? LocalizedError)?.errorDescription
            isSubmissionFailed = true
            return nil
        }
    }
}

private extension ReferenceLetterForm {
    func discardInquiry() {
        inquiry = nil
        draft = IntentFormState(rules: IntentFormRules(fields: { _ in [] }, fieldsToReset: { _ in [] }))
    }
}
