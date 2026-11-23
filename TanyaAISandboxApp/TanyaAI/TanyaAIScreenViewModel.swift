//
//  TanyaAIScreenViewModel.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import TanyaAI
import UIKit

/// View model halaman Tanya AI di host: membaca `repository` UseCase dan menyusun konfigurasi package.
/// Urutan init → history → SSE, retry, pesan, dan status menunggu jawaban milik TanyaAI (`TanyaAIBridge`).
final class TanyaAIScreenViewModel: ScreenContentViewModel {
    @Published var isReferenceLetterAckFailed = false
    let useCase: TanyaAIUseCase
    /// Dibuat sekali bersama view model (milik `@StateObject` destination); UseCase menjadi transport chat.
    @MainActor
    private(set) lazy var bridge = TanyaAIBridge(
        transport: useCase,
        hostServices: SandboxHostServices { [weak self] _ in
            self?.isReferenceLetterAckFailed = true
        },
        onSessionExpired: { [weak self] in self?.didReceiveError(URLError(.userAuthenticationRequired)) },
        onConnectionFailed: { [weak self] error in self?.didReceiveError(error) }
    )
    /// Dibuat sekali: bahasa dan sambutan dibaca saat halaman dibuka, bukan setiap render.
    @MainActor
    private(set) lazy var host = TanyaAIHost(
        // Sandbox: bahasa dari launch option; host memakai Localize_Swift.
        locale: SandboxOptions.current.locale ?? .current,
        welcome: useCase.repository.welcome,
        bridge: bridge,
        // Sama dengan sheet milik host: swipe-back ditahan selama sheet Tanya AI terbuka.
        onSheetChange: { UINavigationController.setPopGestureEnabled(!$0) }
    )

    init(useCase: TanyaAIUseCase) {
        self.useCase = useCase
        super.init()
        useCase.callback.onSubmissionFailed = { [weak self] error in self?.didReceiveError(error) }
        useCase.loadWelcome()
    }
}
