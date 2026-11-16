//
//  ActionCardTests.swift
//  DesignKitTests
//
//  Created by Wendra on 13/11/26.
//

import SwiftUI
import Testing

@testable import DesignKit

/// `.disabled` dari pemakai membuat chevron abu-abu.
@MainActor
struct ActionCardTests {
    private let width: CGFloat = 343

    @Test
    func disablingGreysTheCard() throws {
        try FontFace.registerFonts()
        let disabled = RenderedImage.png(of: card.disabled(true), width: width)
        try #require(disabled != nil)
        #expect(RenderedImage.png(of: card, width: width) != disabled)
    }
}

// MARK: - Helpers

private extension ActionCardTests {
    var card: some View {
        ActionCard(
            title: "Judul",
            description: "Deskripsi",
            onTap: {},
            icon: { Color.clear }
        )
    }
}
