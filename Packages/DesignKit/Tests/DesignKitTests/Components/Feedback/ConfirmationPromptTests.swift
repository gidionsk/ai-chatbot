//
//  ConfirmationPromptTests.swift
//  DesignKit
//
//  Created by Wendra on 20/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Di dalam bottom sheet tombolnya menempel di tepi bawah sebagai footer; di luar sheet tampil biasa di bawah teks,
/// jadi isinya tidak terpotong dan tetap selebar wadah.
@MainActor
struct ConfirmationPromptTests {
    @Test
    func buttonsSitBelowTheTextAtTheFullWidth() throws {
        try FontFace.registerFonts()
        let textOnly = size(of: textBlock)
        let prompt = size(of: confirmationPrompt)
        #expect(prompt.width == width)
        #expect(prompt.height > textOnly.height)
    }
}

// MARK: - Helpers

private extension ConfirmationPromptTests {
    var width: CGFloat { 375 }

    var confirmationPrompt: some View {
        ConfirmationPrompt(
            title: "Are you sure to exit this mode?",
            message: "You're getting back to self service mode",
            confirmTitle: "Yes",
            cancelTitle: "No",
            onConfirm: {},
            onCancel: {}
        )
    }

    var textBlock: some View {
        VStack(spacing: .zero) {
            Text("Are you sure to exit this mode?").designFont(.title)
            Text("You're getting back to self service mode").designFont(.body)
        }
    }

    func size(of content: some View) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: width, height: 2_000))
    }
}
