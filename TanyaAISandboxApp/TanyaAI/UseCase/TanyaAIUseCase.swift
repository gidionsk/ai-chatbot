//
//  TanyaAIUseCase.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import Foundation
import TanyaAI

/// Meniru UseCase Byon: coordinator menulis `input`, UseCase mengolahnya ke `repository`, ViewModel membaca
/// `repository`. Tanpa output karena belum ada halaman berikutnya. UseCase juga menjadi transport chat
/// (`TanyaAIUseCase+Chat`).
final class TanyaAIUseCase {
    let callback: BaseCallback
    var input = TanyaAIInput()
    private(set) var repository = TanyaAIRepository()
    let chatService: TanyaAIChatService
    private let options: SandboxOptions

    init(options: SandboxOptions = .current) {
        let callback = BaseCallback()
        self.callback = callback
        self.options = options
        chatService = TanyaAIChatService(options: options) { callback.onSubmissionFailed($0) }
    }

    /// Dipanggil sekali dari init view model, sebelum `host` dibuat. Input dari halaman sebelumnya dipetakan
    /// ke model TanyaAI; sapaan kosong = tanpa sambutan. Sandbox: `--header-demo` mengosongkan sambutan,
    /// `--broken-icons`/`--slow-icons` mengganti URL ikon.
    func loadWelcome() {
        guard !options.isHeaderDemo, !input.greeting.title.isEmpty else {
            repository.welcome = nil
            return
        }
        let shortcuts =
            options.iconOverrideURL.map { iconURL in input.shortcuts.map { $0.replacingIcon(with: iconURL) } }
            ?? input.shortcuts
        repository.welcome = WelcomeContent(greetings: input.greeting.greeting, shortcuts: shortcuts.map(\.shortcut))
    }
}
