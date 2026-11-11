//
//  MessageComposerTests.swift
//  DesignKit
//
//  Created by Wendra on 10/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Tombol lampiran berada di luar kartu tanpa menambah tinggi composer, karena padding vertikalnya sama dengan
/// padding kartu.
@MainActor
struct MessageComposerTests {
    @Test
    func attachmentKeepsTheComposerHeight() throws {
        try FontFace.registerFonts()
        let plain = size(of: composer(attachment: nil))
        let attached = size(of: composer(attachment: MessageComposerAttachment(label: "Lampirkan") {}))
        #expect(abs(attached.height - plain.height) <= 0.5)
    }
}

// MARK: - Helpers

private extension MessageComposerTests {
    func composer(attachment: MessageComposerAttachment?) -> some View {
        MessageComposer(
            text: .constant(String()), placeholder: "Tanya", actionLabel: "Kirim", attachment: attachment, onSend: {}
        )
    }

    func size(of content: some View) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: 375, height: 800))
    }
}
