//
//  FormFieldTests.swift
//  DesignKitTests
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Field pilihan dan field teks sama tinggi, isi atau placeholder tidak mengubah tinggi, dan pesan error menambah
/// tinggi di bawah kotak. `.disabled` dari pemakai membuat kotaknya abu-abu.
@MainActor
struct FormFieldTests {
    private let width: CGFloat = 375

    @Test
    func aValueAndAPlaceholderKeepTheSameHeight() throws {
        try FontFace.registerFonts()
        let empty = size(of: SelectField(label: "Format", value: nil, placeholder: "Pilih format") {})
        let filled = size(of: SelectField(label: "Format", value: "Hardcopy", placeholder: "Pilih format") {})
        #expect(abs(empty.height - filled.height) <= 0.5)
    }

    @Test
    func selectAndTextFieldsShareTheirHeight() throws {
        try FontFace.registerFonts()
        let select = size(of: SelectField(label: "Format", value: "Hardcopy", placeholder: "Pilih") {})
        let text = size(of: TextInputField(label: "Alamat", text: .constant("Jl. Sudirman"), placeholder: "Tulis"))
        #expect(abs(select.height - text.height) <= 1)
    }

    @Test
    func anErrorAddsALineBelowTheBox() throws {
        try FontFace.registerFonts()
        let plain = size(of: TextInputField(label: "Alamat", text: .constant(String()), placeholder: "Tulis"))
        let invalid = size(
            of: TextInputField(label: "Alamat", text: .constant(String()), placeholder: "Tulis", error: "Wajib diisi")
        )
        #expect(invalid.height > plain.height + FigmaSize.spacingMedium.scaledToArtwork)
    }

    @Test
    func aFieldWithoutALabelStartsAtItsBox() throws {
        try FontFace.registerFonts()
        let labelled = size(of: SelectField(label: "Format", value: nil, placeholder: "Pilih") {})
        let bare = size(of: SelectField(value: nil, placeholder: "Pilih") {})
        #expect(bare.height < labelled.height)
    }

    @Test
    func disablingGreysTheField() throws {
        try FontFace.registerFonts()
        let field = SelectField(value: nil, placeholder: "Pilih") {}
        let disabled = RenderedImage.png(of: field.disabled(true), width: width)
        try #require(disabled != nil)
        #expect(RenderedImage.png(of: field, width: width) != disabled)
    }
}

// MARK: - Helpers

private extension FormFieldTests {
    func size(of content: some View) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: width, height: 800))
    }
}
