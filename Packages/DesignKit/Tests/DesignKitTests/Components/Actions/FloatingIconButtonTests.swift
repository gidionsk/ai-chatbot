//
//  FloatingIconButtonTests.swift
//  DesignKit
//
//  Created by Wendra on 11/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import DesignKit

/// Sisi tombol 1:1 Figma (36), tidak dibesarkan menjadi 44, dan bayangan tidak menambah ukurannya.
@MainActor
struct FloatingIconButtonTests {
    @Test
    func buttonKeepsItsFigmaSide() {
        let button = FloatingIconButton(icon: .arrowDown, label: "Ke pesan terbaru") {}
        let size = UIHostingController(rootView: button).sizeThatFits(in: CGSize(width: 343, height: 800))
        let side = FigmaSize.weightIconMedium.scaledToArtwork
        #expect(size == CGSize(width: side, height: side))
    }
}
