//
//  WelcomeContent.swift
//  TanyaAI
//
//  Created by Wendra on 27/10/26.
//

import Foundation

/// Isi halaman sambutan. Host men-decode response inquiry init dengan model miliknya sendiri lalu
/// memetakannya ke tipe ini; TanyaAI tidak bergantung pada bentuk JSON init.
public struct WelcomeContent: Equatable {
    public let greetings: WelcomeGreeting
    public let shortcuts: [WelcomeShortcut]

    public init(greetings: WelcomeGreeting, shortcuts: [WelcomeShortcut]) {
        self.greetings = greetings
        self.shortcuts = shortcuts
    }
}
