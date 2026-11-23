//
//  SandboxHostServices.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 23/11/26.
//

import Foundation
import TanyaAI

@MainActor
final class SandboxHostServices: TanyaAIHostServices {
    private let onAcknowledgementError: (Error) -> Void

    private(set) lazy var referenceLetter: ReferenceLetterService? = {
        let options = SandboxOptions.current
        guard options.isFormDemo else { return nil }
        return SandboxReferenceLetterService(
            locale: options.locale ?? .current,
            onAcknowledgementError: onAcknowledgementError
        )
    }()

    init(onAcknowledgementError: @escaping (Error) -> Void) {
        self.onAcknowledgementError = onAcknowledgementError
    }
}
