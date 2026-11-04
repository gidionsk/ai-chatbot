//
//  TanyaAIEntryOutput.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 30/10/26.
//

/// Data untuk halaman Tanya AI; ditulis `TanyaAIEntryUseCase`, dibaca coordinator lalu dioper ke `TanyaAICoordinator`.
struct TanyaAIEntryOutput {
    var greeting = TanyaAIInitGreeting()
    var shortcuts: [TanyaAIInitShortcut] = []
}
