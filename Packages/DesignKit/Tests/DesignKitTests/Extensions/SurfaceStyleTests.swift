//
//  SurfaceStyleTests.swift
//  DesignKit
//
//  Created by Wendra on 22/10/26.
//

import SwiftUI
import Testing

@testable import DesignKit

@MainActor
struct SurfaceStyleTests {
    @Test
    func surfaceStylesOnlyDrawBehindContentWithoutChangingLayout() {
        let plain = size(of: Text("Kartu").padding())
        #expect(size(of: Text("Kartu").padding().cardStyle()) == plain)
        #expect(size(of: Text("Kartu").padding().cardStyle(isOutlined: false)) == plain)
        #expect(size(of: Text("Kartu").padding().designShadow()) == plain)
    }
}

// MARK: - Helpers

private extension SurfaceStyleTests {
    func size(of content: some View) -> CGSize {
        UIHostingController(rootView: content).sizeThatFits(in: CGSize(width: 375, height: 800))
    }
}
