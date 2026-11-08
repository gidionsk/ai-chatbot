//
//  WelcomeGreeting.swift
//  TanyaAI
//
//  Created by Wendra on 27/10/26.
//

import Foundation

/// Sapaan di bawah emblem, misalnya "Hi, Lara Croft!" dan kalimat pendukungnya. Teks dari BE.
public struct WelcomeGreeting: Equatable {
    public let title: String
    public let description: String

    public init(title: String, description: String) {
        self.title = title
        self.description = description
    }
}
