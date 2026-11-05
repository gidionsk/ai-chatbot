//
//  EnvironmentValues+ScreenViewport.swift
//  DesignKit
//
//  Created by Wendra on 5/11/26.
//

import SwiftUI

private struct ScreenViewportKey: EnvironmentKey {
    static let defaultValue = ScreenViewport()
}

public extension EnvironmentValues {
    /// Diisi `ScreenContainer` untuk kontennya; di luar container nilainya nol.
    var screenViewport: ScreenViewport {
        get { self[ScreenViewportKey.self] }
        set { self[ScreenViewportKey.self] = newValue }
    }
}
