//
//  FormSubmissionPhase.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Lifecycle form transaksi. Transport failure setelah submit dibedakan dari penolakan BE agar tidak mengulang
/// transaksi yang mungkin sudah diterima. Dipakai flow form, bukan koneksi chat-gateway yang boleh auto-retry.
enum FormSubmissionPhase: Equatable {
    case idle, loading, loadFailed, editing, awaitingPIN, verifying, submitting
    case completed, cancelled, blocked, uncertain, history

    var isBusy: Bool { self == .verifying || self == .submitting }
}

enum FormSubmissionFailure {
    case verificationUnavailable
}
