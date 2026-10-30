//
//  LocalizationTests.swift
//  TanyaAI
//
//  Created by Wendra on 15/10/26.
//

import DesignKit
import Foundation
import Testing

@testable import TanyaAI

struct LocalizationTests {
    @Test
    func allSupportedLanguagesHaveTranslatedLabels() {
        let cases = [("en", "Send message"), ("id", "Kirim pesan"), ("zh-Hans", "发送消息"), ("zh_CN", "发送消息")]
        for (identifier, expected) in cases {
            let locale = Locale(identifier: identifier)
            #expect(String(ChatCopy.send, locale: locale) == expected)
            let placeholder = String(ChatCopy.placeholder, locale: locale)
            #expect(!placeholder.isEmpty)
            #expect(placeholder != "chat.placeholder")
        }
        for (identifier, expected) in [("en", "Back"), ("id", "Kembali"), ("zh-Hans", "返回")] {
            let locale = Locale(identifier: identifier)
            #expect(String(ChatCopy.back, locale: locale) == expected)
            #expect(String(ChatCopy.title, locale: locale) == "Tanya AI")
        }
    }

    /// Copy per bahasa: judul sambutan, lalu label titik bergerak dan stop composer.
    @Test(arguments: [
        ("en", ["Start here:", "Sending message", "Stop response"]),
        ("id", ["Mulai dari sini:", "Mengirim pesan", "Hentikan jawaban"]),
        ("zh-Hans", ["从这里开始：", "正在发送消息", "停止回答"])
    ])
    func welcomeAndComposerPhaseCopyFollowTheHostLocale(language: String, expected: [String]) {
        let locale = Locale(identifier: language)
        let copies = [ChatCopy.shortcutsTitle, .sending, .stop].map { String($0, locale: locale) }
        #expect(copies == expected)
    }

    @Test
    func unsupportedLanguageFallsBackToEnglish() {
        #expect(String(ChatCopy.send, locale: Locale(identifier: "fr_FR")) == "Send message")
    }

    @Test(arguments: ["en", "id", "zh-Hans"])
    func copyKeysMatchTheStringsTableExactly(language: String) throws {
        let path = try #require(
            Bundle.module.path(
                forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: language
            )
        )
        let table = try #require(NSDictionary(contentsOfFile: path) as? [String: String])
        #expect(Set(table.keys) == Set(ChatCopy.allCases.map(\.rawValue)))
        #expect(table.values.allSatisfy { !$0.isEmpty })
    }

    @Test
    func missingKeyReturnsTheKeyItself() {
        let text = String(key: "chat.unknown", bundle: .module, locale: Locale(identifier: "id"))
        #expect(text == "chat.unknown")
    }
}
