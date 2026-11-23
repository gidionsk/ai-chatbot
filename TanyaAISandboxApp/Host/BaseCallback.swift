//
//  BaseCallback.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import Foundation

/// Tiruan callback host: use case melapor ke view model lewat closure.
final class BaseCallback {
    var onSubmissionFailed: (Error) -> Void = { _ in }
}
