//
//  FormToggleTests.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

@MainActor
struct FormToggleTests {
    @Test(arguments: [false, true], [false, true])
    func rendersAtAvailableWidth(isOn: Bool, isEnabled: Bool) throws {
        try FontFace.registerFonts()
        let width: CGFloat = 343
        let view = FormToggle(title: "Tampilkan informasi saldo", isOn: .constant(isOn), isEnabled: isEnabled)
        let size = UIHostingController(rootView: view)
            .sizeThatFits(in: CGSize(width: width, height: 800))
        #expect(size.width == width)
        #expect(abs(size.height - CustomSizes.FormToggle.height.scaledToArtwork) <= 0.5)
    }

    @Test(arguments: [false, true])
    func longLabelWrapsWithoutIncreasingTheRowWidth(isParentDisabled: Bool) throws {
        try FontFace.registerFonts()
        let width: CGFloat = 200
        let view = FormToggle(
            title: "Tampilkan informasi saldo beserta seluruh dana investasi dalam surat referensi",
            isOn: .constant(false)
        )
        .disabled(isParentDisabled)
        let size = UIHostingController(rootView: view)
            .sizeThatFits(in: CGSize(width: width, height: 800))
        #expect(size.width == width)
        #expect(size.height > CustomSizes.FormToggle.height.scaledToArtwork)
    }
}
