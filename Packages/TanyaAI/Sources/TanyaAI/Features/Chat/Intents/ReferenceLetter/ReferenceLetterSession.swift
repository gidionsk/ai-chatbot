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
    private var pendingRequest: ReferenceLetterRequest?
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

    /// True = semua field valid dan snapshot ACK siap. Error input tetap terlihat hingga caller mengedit field itu.
    func confirm() -> Bool {
        guard phase == .editing, let inquiry else { return false }
        invalidFields = draft.invalidFields(in: inquiry)
        guard let request = ReferenceLetterRequest(inquiry: inquiry, draft: draft) else { return false }
        pendingRequest = request
        errorMessage = nil
        failure = nil
        phase = .awaitingPIN
        return true
    }

    func clearResolvedErrors() {
        guard let inquiry else { return }
        invalidFields.formIntersection(draft.invalidFields(in: inquiry))
    }

    /// Satu panggilan aktif. PIN tidak menjadi properti, request ACK, log, atau history.
    func submit(pin: String) async {
        guard phase == .awaitingPIN, let request = pendingRequest,
            TransactionPINRules.isValid(pin)
        else { return }
        phase = .verifying
        errorMessage = nil
        failure = nil
        let current = generation
        do {
            let verification = try await service.verify(pin: pin)
            guard current == generation, !Task.isCancelled else { return }
            guard !verification.responseCodeOTP.isEmpty else {
                failure = .verificationUnavailable
                phase = .awaitingPIN
                return
            }
            phase = .submitting
            let result = try await service.acknowledge(request.authorized(with: verification))
            guard current == generation else { return }
            submittedPurpose = request.purpose.value
            receipt = result
            pendingRequest = nil
            phase = .completed
        } catch {
            guard current == generation else { return }
            handle(error)
        }
    }

    func dismissPIN() {
        guard phase == .awaitingPIN else { return }
        pendingRequest = nil
        errorMessage = nil
        failure = nil
        phase = .editing
    }

    func cancel() {
        guard !phase.isBusy, phase != .completed else { return }
        invalidate()
    }

    /// Meninggalkan halaman sebelum verify selesai tidak boleh memulai ACK sesudahnya. ACK yang sudah terkirim
    /// tidak dianggap batal: statusnya belum pasti dan harus diperiksa host, tanpa pengiriman ulang otomatis.
    func leaveScreen() {
        switch phase {
        case .awaitingPIN, .verifying:
            invalidate()
        case .submitting:
            generation = UUID()
            pendingRequest = nil
            phase = .uncertain
        default:
            break
        }
    }

    /// Conversation berubah/logout: respons lama tidak boleh memanggil ACK atau mengubah form baru.
    func invalidate() {
        generation = UUID()
        pendingRequest = nil
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
                pendingRequest = nil
                phase = .uncertain
                return
            }
            errorMessage = message
            pendingRequest = nil
            phase = .editing
            return
        }
        if let error = error as? ReferenceLetterServiceError {
            switch error {
            case .invalidPIN(let message):
                errorMessage = message
                phase = .awaitingPIN
            case .blockedPIN(let message):
                errorMessage = message
                pendingRequest = nil
                phase = .blocked
            case .verification(let message):
                errorMessage = message
                phase = .awaitingPIN
            case .rejected(let message):
                errorMessage = message
                phase = .awaitingPIN
            }
            return
        }
        failure = .verificationUnavailable
        phase = .awaitingPIN
    }
}
