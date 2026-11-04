//
//  TanyaAIEntryCallback.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 30/10/26.
//

/// Dipasang coordinator, dipicu `TanyaAIEntryUseCase` setelah inquiry selesai.
struct TanyaAIEntryCallback {
    var onStartTanyaAI: () -> Void = {}
}
