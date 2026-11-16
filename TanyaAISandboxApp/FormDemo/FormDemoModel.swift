//
//  FormDemoModel.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 12/11/26.
//

import Combine
import DesignKit
import Foundation

/// Sandbox saja: state form contoh `--form-demo`, untuk mencoba komponen field DesignKit. Validasi hanya saat
/// Konfirmasi: semua field kosong ditandai, dan pilihan kosong paling atas langsung membuka sheet-nya. Form yang valid
/// membuka sheet PIN; "service host" tiruan menerima `SandboxOptions.formPin` saja. PIN hanya ada di memori selama
/// diketik dan dikosongkan setelah diperiksa atau saat sheet ditutup; tidak pernah di-log. Mesin form yang sebenarnya
/// menyusul di TanyaAI. Class karena `ObservableObject` mewajibkannya.
@MainActor
final class FormDemoModel: ObservableObject {
    @Published private(set) var formatID: String?
    @Published private(set) var accountIDs: [String] = []
    @Published var address = String() {
        didSet { invalidFields.remove(.address) }
    }
    @Published var isBalanceShown = false
    @Published private(set) var invalidFields: Set<FormDemoField> = []
    @Published var sheet: FormDemoSheet? {
        didSet { clearPinUnlessOpen() }
    }
    @Published var pin = String() {
        didSet { clearRejectionOnTyping() }
    }
    @Published private(set) var isPinRejected = false
    @Published private(set) var isVerifying = false
    @Published private(set) var isSubmitted = false
    /// Nil = masih diambil dari "service host".
    @Published private(set) var accountOptions: [OptionItem]?

    var isHardcopy: Bool { formatID == SandboxOptions.formHardcopyID }

    func open(_ sheet: FormDemoSheet) {
        self.sheet = sheet
        guard sheet == .accounts, accountOptions == nil else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + SandboxOptions.formLoadDelay) { [weak self] in
            self?.accountOptions = SandboxOptions.formAccounts
        }
    }

    /// Field yang bergantung pada format di-reset saat tidak lagi tampil.
    func selectFormat(_ ids: [String]) {
        formatID = ids.first
        invalidFields.remove(.format)
        sheet = nil
        guard !isHardcopy else { return }
        address = String()
    }

    func selectAccounts(_ ids: [String]) {
        accountIDs = ids
        invalidFields.remove(.accounts)
        sheet = nil
    }

    /// Batalkan: form kembali kosong seperti baru dibuka.
    func cancel() {
        formatID = nil
        accountIDs = []
        address = String()
        isBalanceShown = false
        invalidFields = []
        isSubmitted = false
    }

    /// Form valid = sheet PIN; selain itu pilihan kosong paling atas dibuka.
    func confirm() {
        let invalid = FormDemoField.allCases.filter(isInvalid)
        invalidFields = Set(invalid)
        guard let sheet = invalid.isEmpty ? .pin : invalid.compactMap(\.sheet).first else { return }
        open(sheet)
    }

    /// Seolah service host memeriksa PIN: keypad nonaktif dan sheet terkunci selama jeda.
    func verify(_ enteredPin: String) {
        isVerifying = true
        let isAccepted = enteredPin == SandboxOptions.formPin
        DispatchQueue.main.asyncAfter(deadline: .now() + SandboxOptions.formVerifyDelay) { [weak self] in
            self?.finishVerifying(isAccepted: isAccepted)
        }
    }
}

// MARK: - Helpers

private extension FormDemoModel {
    /// PIN ditolak: sheet tetap terbuka, titik dikosongkan, error tampil. Diterima: sheet ditutup.
    func finishVerifying(isAccepted: Bool) {
        isVerifying = false
        pin = String()
        guard isAccepted else {
            isPinRejected = true
            return
        }
        sheet = nil
        isSubmitted = true
    }

    func clearPinUnlessOpen() {
        guard sheet != .pin else { return }
        pin = String()
        isPinRejected = false
    }

    /// Error PIN salah hilang begitu nasabah mulai mengetik lagi.
    func clearRejectionOnTyping() {
        guard !pin.isEmpty else { return }
        isPinRejected = false
    }

    func isInvalid(_ field: FormDemoField) -> Bool {
        switch field {
        case .format:
            return formatID == nil
        case .accounts:
            return accountIDs.isEmpty
        case .address:
            return isHardcopy && address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
