//
//  FormSubmissionPhase.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Lifecycle inquiry/form sebelum capability submit dipasang.
enum FormSubmissionPhase: Equatable {
    case idle, loading, loadFailed, editing, cancelled, history
}
