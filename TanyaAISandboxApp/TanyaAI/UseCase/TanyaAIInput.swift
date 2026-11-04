//
//  TanyaAIInput.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 30/10/26.
//

/// Data dari halaman sebelumnya; ditulis coordinator (destination) dan dibaca `TanyaAIUseCase`.
struct TanyaAIInput {
    /// Hasil inquiry init BE host; default kosong bila halaman sebelumnya tidak punya data.
    var greeting = TanyaAIInitGreeting()
    var shortcuts: [TanyaAIInitShortcut] = []
}
