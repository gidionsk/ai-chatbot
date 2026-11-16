//
//  FormSubmissionPhase.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Lifecycle form; otorisasi host dan submit tidak mengikuti retry transport chat-gateway.
enum FormSubmissionPhase: Equatable {
    case idle, loading, loadFailed, editing, authorizing, submitting
    case completed, cancelled, uncertain, history

    var isBusy: Bool { self == .authorizing || self == .submitting }
}

enum FormSubmissionFailure {
    case authorizationUnavailable
}
