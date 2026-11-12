//
//  FormToggleTests.swift
//  DesignKit
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

@MainActor
struct FormToggleTests {
    @Test
    func rendersAtAvailableWidth() throws {
        try FontFace.registerFonts()
        let width: CGFloat = 343
        let view = FormToggle(title: "Tampilkan informasi saldo", isOn: .constant(false))
        let size = UIHostingController(rootView: view)
            .sizeThatFits(in: CGSize(width: width, height: 800))
        #expect(size.width == width)
        #expect(size.height >= 24)
    }

    @Test
    func supportsEnabledAndDisabledStates() throws {
        try FontFace.registerFonts()
        for isEnabled in [true, false] {
            let view = FormToggle(
                title: "Tampilkan dana investasi",
                isOn: .constant(true),
                isEnabled: isEnabled
            )
            let size = UIHostingController(rootView: view)
                .sizeThatFits(in: CGSize(width: 343, height: 800))
            #expect(size.height >= 24)
        }
    }
}
