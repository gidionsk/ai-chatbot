//
//  DesignFontRoleTests.swift
//  DesignKitTests
//
//  Created by Wendra on 14/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Setiap peran teks memakai face Fira Sans yang terdaftar dan ukuran Figma yang di-scale, bukan system font.
@MainActor
struct DesignFontRoleTests {
    @Test
    func everyRoleResolvesToARegisteredFiraSansFace() throws {
        try FontFace.registerFonts()
        for role in DesignFontRole.allCases {
            #expect(role.uiFont.fontName == role.face.postScriptName, "\(role)")
            #expect(role.uiFont.pointSize == role.size.scaledToArtwork, "\(role)")
        }
    }

    @Test
    func rolesKeepTheirFigmaPairs() {
        #expect(DesignFontRole.title.face == .firaSansSemiBold)
        #expect(DesignFontRole.title.size == FigmaSize.typographySizeHeadingSmall20)
        #expect(DesignFontRole.headerTitle.face == .firaSansBold)
        #expect(DesignFontRole.headerTitle.size == FigmaSize.typographySizeDisplayNormal16)
        #expect(DesignFontRole.body.face == .firaSansRegular)
        #expect(DesignFontRole.body.size == FigmaSize.typographySizeDisplaySmall14)
        #expect(DesignFontRole.captionItalic.face == .firaSansItalic)
        #expect(DesignFontRole.captionItalic.size == FigmaSize.typographySizeDisplayTiny12)
    }

    /// `.designFont` memberi ukuran teks yang sama dengan font peran itu sendiri.
    @Test
    func theModifierAppliesTheRoleFont() throws {
        try FontFace.registerFonts()
        let viaModifier = size(of: Text("Ag").designFont(.title))
        #expect(viaModifier == size(of: Text("Ag").font(DesignFontRole.title.font)))
        #expect(viaModifier != size(of: Text("Ag").designFont(.caption)))
    }
}

// MARK: - Helpers

private extension DesignFontRoleTests {
    func size(of content: some View) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: 375, height: 200))
    }
}
