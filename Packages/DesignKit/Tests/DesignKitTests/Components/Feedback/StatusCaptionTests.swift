//
//  StatusCaptionTests.swift
//  DesignKit
//
//  Created by Wendra on 19/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Teks status selebar wadah, supaya rata kiri di bawah pesan terakhir.
@MainActor
struct StatusCaptionTests {
    @Test
    func captionFillsTheWidthOfItsContainer() throws {
        try FontFace.registerFonts()
        let size = UIHostingController(rootView: StatusCaption(text: text))
            .sizeThatFits(in: CGSize(width: width, height: 2_000))
        #expect(size.width == width)
    }
}

// MARK: - Helpers

private extension StatusCaptionTests {
    var text: String { "Agen sedang mengetik..." }

    var width: CGFloat { 343 }
}
