//
//  TanyaAIScreenViewModelTests.swift
//  TanyaAISandboxTests
//
//  Created by Wendra on 27/10/26.
//

import Foundation
import TanyaAI
import Testing

@testable import Tanya_AI_Sandbox

struct TanyaAIScreenViewModelTests {
    /// View model memicu pengolahan input sekali saat dibuat; halaman membaca hasilnya dari repository.
    @Test
    func creatingTheViewModelLoadsTheWelcomeFromTheInput() {
        let entry = TanyaAIEntryUseCase()
        entry.inquire()
        let useCase = TanyaAIUseCase(options: SandboxOptions(arguments: []))
        useCase.input.greeting = entry.output.greeting
        useCase.input.shortcuts = entry.output.shortcuts
        _ = TanyaAIScreenViewModel(useCase: useCase, intentServices: .init())
        #expect(useCase.repository.welcome?.greetings.title == "Hi, Lara Croft!")
    }

    /// Bridge memegang callback secara weak: view model tetap dilepas walau bridge masih hidup.
    @MainActor
    @Test
    func bridgeDoesNotKeepTheViewModelAlive() {
        weak var releasedViewModel: TanyaAIScreenViewModel?
        var bridge: TanyaAIBridge?
        do {
            let viewModel = TanyaAIScreenViewModel(
                useCase: TanyaAIUseCase(options: SandboxOptions(arguments: [])),
                intentServices: .init()
            )
            releasedViewModel = viewModel
            bridge = viewModel.bridge
        }
        #expect(bridge != nil)
        #expect(releasedViewModel == nil)
    }

    @MainActor
    @Test
    func configuredIntentCanRequestAHostSheet() throws {
        let options = SandboxOptions(arguments: ["--language", "en", "--form-demo"])
        let useCase = TanyaAIUseCase(options: options)
        let callback = useCase.callback
        let service = try #require(
            SandboxReferenceLetterService.make(options: options) { message in
                callback.onHostSheetRequested(message)
            })
        let viewModel = TanyaAIScreenViewModel(
            useCase: useCase,
            intentServices: TanyaAIIntentServices(referenceLetter: service)
        )

        #expect(viewModel.hostSheetMessage == nil)
        service.presentAcknowledgementError(URLError(.badServerResponse))
        #expect(viewModel.hostSheetMessage == "The host could not submit your reference letter.")
    }
}
