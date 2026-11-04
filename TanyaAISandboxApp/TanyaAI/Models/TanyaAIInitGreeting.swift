//
//  TanyaAIInitGreeting.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 28/10/26.
//

import TanyaAI

/// `data.greetings` inquiry init: sapaan di bawah emblem. Default kosong = belum ada data (tanpa sambutan).
struct TanyaAIInitGreeting: Decodable {
    var title = String()
    var description = String()

    var greeting: WelcomeGreeting {
        WelcomeGreeting(title: title, description: description)
    }
}
