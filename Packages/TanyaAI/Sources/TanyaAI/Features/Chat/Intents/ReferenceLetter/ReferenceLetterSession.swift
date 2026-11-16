//
//  ReferenceLetterSession.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import Combine
import DesignKit
import Foundation

/// Satu instance per id pesan pemicu, dimiliki bridge di luar sel. Ketikan hanya diamati baris instance ini.
@MainActor
final class ReferenceLetterSession: ObservableObject {
    @Published private(set) var phase = FormSubmissionPhase.idle
    @Published private(set) var inquiry: ReferenceLetterInquiry?
    @Published var draft = ReferenceLetterDraft()
    @Published private(set) var invalidFields: Set<ReferenceLetterFieldID> = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var failure: FormSubmissionFailure?
    @Published private(set) var receipt: ReferenceLetterReceipt?
    private(set) var submittedPurpose: String?
    private var generation = UUID()
    private let service: ReferenceLetterService
    private let submission: ReferenceLetterSubmissionService?

    var isSubmissionAvailable: Bool { submission != nil }

    init(
        service: ReferenceLetterService,
        submission: ReferenceLetterSubmissionService? = nil,
        isHistory: Bool = false
    ) {
        self.service = service
        self.submission = submission
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

    /// Snapshot diambil sebelum meminta PIN existing host. Tidak ada angka PIN yang masuk ke SDK.
    func submit() async {
        guard phase == .editing, let inquiry, let submission else { return }
        invalidFields = draft.invalidFields(in: inquiry)
        guard let request = ReferenceLetterRequest(inquiry: inquiry, draft: draft) else { return }
        phase = .authorizing
        errorMessage = nil
        failure = nil
        let current = generation
        do {
            let authorization = try await submission.authorize()
            guard current == generation else { return }
            guard !Task.isCancelled else {
                phase = .editing
                return
            }
            guard let authorization else {
                phase = .editing
                return
            }
            guard !authorization.responseCodeOTP.isEmpty else {
                failure = .authorizationUnavailable
                phase = .editing
                return
            }
            phase = .submitting
            let result = try await submission.acknowledge(request, authorization: authorization)
            guard current == generation else { return }
            submittedPurpose = request.purpose.value
            receipt = result
            phase = .completed
        } catch {
            guard current == generation else { return }
            handle(error)
        }
    }

    func cancel() {
        guard !phase.isBusy, phase != .completed else { return }
        invalidate()
    }

    /// Meninggalkan halaman sebelum verify selesai tidak boleh memulai ACK sesudahnya. ACK yang sudah terkirim
    /// tidak dianggap batal: statusnya belum pasti dan harus diperiksa host, tanpa pengiriman ulang otomatis.
    func leaveScreen() {
        switch phase {
        case .loading, .authorizing:
            invalidate()
        case .submitting:
            generation = UUID()
            phase = .uncertain
        default:
            break
        }
    }

    /// Conversation berubah/logout: respons lama tidak boleh memanggil ACK atau mengubah form baru.
    func invalidate() {
        generation = UUID()
        errorMessage = nil
        failure = nil
        phase = .cancelled
    }
}

// MARK: - Helpers

private extension ReferenceLetterSession {
    func handle(_ error: Error) {
        if phase == .submitting {
            guard case ReferenceLetterServiceError.rejected(let message) = error else {
                phase = .uncertain
                return
            }
            errorMessage = message
            phase = .editing
            return
        }
        if let error = error as? ReferenceLetterServiceError {
            switch error {
            case .authorization(let message), .rejected(let message):
                errorMessage = message
            }
            phase = .editing
            return
        }
        failure = .authorizationUnavailable
        phase = .editing
    }
}
