//
//  TanyaAIBridge+Delivery.swift
//  TanyaAI
//
//  Created by Wendra on 2/11/26.
//

@testable import TanyaAI

extension TanyaAIBridge {
    /// Kirim lalu tunggu respons gateway diproses. False = ditolak sebelum diteruskan ke gateway.
    func sendAndWait(_ text: String) async -> Bool {
        guard let delivery = send(text) else { return false }
        await delivery.value
        return true
    }
}
