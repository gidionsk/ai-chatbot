//
//  WelcomeShortcut.swift
//  TanyaAI
//
//  Created by Wendra on 27/10/26.
//

import Foundation

/// Satu kartu shortcut di halaman sambutan. Saat diketuk, `prompt` dikirim sebagai chat.
public struct WelcomeShortcut: Equatable {
    public let title: String
    public let description: String
    /// Nil bila host tidak punya URL valid; kartu tetap tampil dengan ikon fallback.
    public let iconURL: URL?
    public let prompt: String

    public init(title: String, description: String, iconURL: URL?, prompt: String) {
        self.title = title
        self.description = description
        self.iconURL = iconURL
        self.prompt = prompt
    }
}
