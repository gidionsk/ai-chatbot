//
//  DesignColorsTests.swift
//  DesignKit
//
//  Created by Wendra on 17/10/26.
//

import SwiftUI
import Testing

@testable import DesignKit

@MainActor
struct DesignColorsTests {
    @Test
    func defaultPaletteWithoutHostTheme() {
        let probe = PaletteProbe()
        render(PaletteReader(probe: probe))
        #expect(probe.palette is DefaultColorConstants)
    }

    @Test
    func themeReachesNestedComponents() {
        let probe = PaletteProbe()
        render(VStack { PaletteReader(probe: probe) }.designColors(PremierColorConstants()))
        #expect(probe.palette is PremierColorConstants)
    }

    @Test
    func defaultAreaIgnoresParentTheme() {
        let themed = PaletteProbe()
        let untouched = PaletteProbe()
        render(
            VStack {
                PaletteReader(probe: themed)
                VStack { PaletteReader(probe: untouched) }.defaultDesignColors()
            }
            .designColors(PrivateColorConstants())
        )
        #expect(themed.palette is PrivateColorConstants)
        #expect(untouched.palette is DefaultColorConstants)
    }

    private func render(_ content: some View) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 200))
        window.rootViewController = UIHostingController(rootView: content)
        window.makeKeyAndVisible()
        window.rootViewController?.view.layoutIfNeeded()
        window.isHidden = true
    }
}

private final class PaletteProbe {
    var palette: (any FigmaColorProtocol)?
}

private struct PaletteReader: View {
    @Environment(\.designColors)
    private var colors
    let probe: PaletteProbe

    var body: some View {
        probe.palette = colors
        return Color.clear.frame(width: 1, height: 1)
    }
}
