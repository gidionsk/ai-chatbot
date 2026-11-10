//
//  View+DesignColors.swift
//  DesignKit
//
//  Created by Wendra on 17/10/26.
//

import SwiftUI

/// Satu sumber palette untuk seluruh subtree; komponen membaca nilai ini dari environment.
private struct DesignColorsKey: EnvironmentKey {
    static let defaultValue: any FigmaColorProtocol = DefaultColorConstants()
}

public extension EnvironmentValues {
    /// Palette aktif. Tanpa pengaturan host, nilainya `DefaultColorConstants`.
    var designColors: any FigmaColorProtocol {
        get { self[DesignColorsKey.self] }
        set { self[DesignColorsKey.self] = newValue }
    }
}

public extension View {
    /// Pasang sekali di root area yang memakai theme, misalnya `PremierColorConstants()`.
    func designColors(_ colors: any FigmaColorProtocol) -> some View {
        environment(\.designColors, colors)
    }

    /// Area bebas theme: subtree ini selalu memakai palette default walaupun parent memilih theme lain.
    func defaultDesignColors() -> some View {
        designColors(DefaultColorConstants())
    }
}
