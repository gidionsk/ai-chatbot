//
//  TanyaAIScreenViewModelTests.swift
//  TanyaAISandboxTests
//
//  Created by Wendra on 27/10/26.
//

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
        _ = TanyaAIScreenViewModel(useCase: useCase)
        #expect(useCase.repository.welcome?.greetings.title == "Hi, Lara Croft!")
    }

    /// Bridge memegang callback secara weak: view model tetap dilepas walau bridge masih hidup.
    @MainActor
    @Test
    func bridgeDoesNotKeepTheViewModelAlive() {
        weak var releasedViewModel: TanyaAIScreenViewModel?
        var bridge: TanyaAIBridge?
        do {
            let viewModel = TanyaAIScreenViewModel(useCase: TanyaAIUseCase(options: SandboxOptions(arguments: [])))
            releasedViewModel = viewModel
            bridge = viewModel.bridge
        }
        #expect(bridge != nil)
        #expect(releasedViewModel == nil)
    }
}
