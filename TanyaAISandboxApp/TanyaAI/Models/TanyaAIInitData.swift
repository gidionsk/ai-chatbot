//
//  TanyaAIInitData.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 28/10/26.
//

/// Objek `data` inquiry init milik host; hanya model decode. Yang dioper ke halaman Tanya AI cukup
/// `greetings` dan `shortcuts`. `isTncAgreed`/`tncCode` belum dipakai sandbox.
struct TanyaAIInitData: Decodable {
    let greetings: TanyaAIInitGreeting
    let shortcuts: [TanyaAIInitShortcut]
}
