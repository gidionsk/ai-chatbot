//
//  TanyaAIDestination.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import SwiftUI
import TanyaAI

/// Pemilik view model halaman Tanya AI. Autoclosure `@StateObject` dijalankan sekali saat halaman di-push:
/// UseCase dibuat, input ditulis, lalu view model dibuat. Render ulang coordinator tidak membuat ulang keduanya.
@MainActor
struct TanyaAIDestination: View {
    @StateObject private var viewModel: TanyaAIScreenViewModel
    let onBack: () -> Void

    init(greeting: TanyaAIInitGreeting, shortcuts: [TanyaAIInitShortcut], onBack: @escaping () -> Void) {
        _viewModel = StateObject(
            wrappedValue: {
                let options = SandboxOptions.current
                let useCase = TanyaAIUseCase(options: options)
                useCase.input.greeting = greeting
                useCase.input.shortcuts = shortcuts

                let callback = useCase.callback
                let referenceLetter = SandboxReferenceLetterService.make(options: options) { message in
                    callback.onHostSheetRequested(message)
                }
                return TanyaAIScreenViewModel(
                    useCase: useCase,
                    intentServices: TanyaAIIntentServices(referenceLetter: referenceLetter)
                )
            }())
        self.onBack = onBack
    }

    var body: some View {
        Screen {
            TanyaAIScreen(viewModel: viewModel, onBack: onBack)
        }
    }
}
