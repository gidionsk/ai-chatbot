//
//  TanyaAIInitShortcut.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 28/10/26.
//

import Foundation
import TanyaAI

/// `data.shortcuts[]` inquiry init. Nama property sama dengan key BE (`iconUrl`), jadi decode tanpa CodingKey.
struct TanyaAIInitShortcut: Decodable {
    let title: String
    let description: String
    let iconUrl: String?
    let prompt: String

    /// `iconUrl` kosong/tidak valid menjadi nil sehingga kartu memakai ikon fallback.
    var shortcut: WelcomeShortcut {
        WelcomeShortcut(
            title: title, description: description, iconURL: iconUrl.flatMap(URL.init(string:)), prompt: prompt
        )
    }

    /// Sandbox: isi tetap dari BE, hanya URL ikon yang diganti.
    func replacingIcon(with iconURL: URL) -> TanyaAIInitShortcut {
        TanyaAIInitShortcut(title: title, description: description, iconUrl: iconURL.absoluteString, prompt: prompt)
    }
}
