//
//  PinEntryTests.swift
//  DesignKitTests
//
//  Created by Wendra on 16/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// `PinEntry` selebar wadah, tingginya tetap saat error muncul, titiknya mengikuti panjang PIN tanpa menampilkan
/// angkanya, dan `.disabled` dari pemakai membuat keypad abu-abu.
@MainActor
struct PinEntryTests {
    private let width: CGFloat = 375

    @Test
    func theEntrySpansItsContainerAndKeepsItsHeightWhenAnErrorAppears() throws {
        try FontFace.registerFonts()
        let plain = size(of: entry(pin: "12"))
        let failed = size(of: entry(pin: String(), error: "PIN salah"))
        #expect(abs(plain.width - width) <= 0.5)
        #expect(abs(plain.height - failed.height) <= 0.5)
    }

    @Test
    func theDotsFollowThePinLength() throws {
        try FontFace.registerFonts()
        let empty = RenderedImage.png(of: entry(pin: String()), width: width)
        try #require(empty != nil)
        let half = RenderedImage.png(of: entry(pin: "123"), width: width)
        #expect(half != empty)
        #expect(half == RenderedImage.png(of: entry(pin: "987"), width: width), "angkanya tidak tampil")
    }

    @Test
    func disablingGreysTheKeypad() throws {
        try FontFace.registerFonts()
        let enabled = RenderedImage.png(of: entry(pin: "1"), width: width)
        try #require(enabled != nil)
        #expect(RenderedImage.png(of: entry(pin: "1").disabled(true), width: width) != enabled)
    }
}

// MARK: - Helpers

private extension PinEntryTests {
    func entry(pin: String, error: String? = nil) -> some View {
        PinEntry(
            title: "Masukkan PIN",
            pin: .constant(pin),
            length: 6,
            error: error,
            deleteLabel: "Hapus",
            onComplete: { _ in }
        )
    }

    func size(of content: some View) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: width, height: 800))
    }
}
