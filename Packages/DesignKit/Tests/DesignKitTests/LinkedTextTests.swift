//
//  LinkedTextTests.swift
//  DesignKitTests
//
//  Created by Wendra on 6/11/26.
//

import SwiftUI
import Testing

@testable import DesignKit

struct LinkedTextTests {
    @Test
    func onlyTheLinkIsColoredAndUnderlined() throws {
        let text = AttributedString.linked(markdown: "Baca [ketentuan](terms) ini.", linkColor: .red)
        let runs = Array(text.runs)
        #expect(runs.count == 3)
        let link = try #require(runs.first { $0.link != nil })
        #expect(String(text[link.range].characters) == "ketentuan")
        #expect(link[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] == .red)
        #expect(link[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] == .single)
        let plain = try #require(runs.first { $0.link == nil })
        #expect(plain[AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute.self] == nil)
        #expect(plain[AttributeScopes.SwiftUIAttributes.UnderlineStyleAttribute.self] == nil)
    }

    @Test
    func textWithoutALinkStaysPlain() {
        let text = AttributedString.linked(markdown: "Tanpa link", linkColor: .red)
        #expect(String(text.characters) == "Tanpa link")
        #expect(text.runs.allSatisfy { $0.link == nil })
    }
}
