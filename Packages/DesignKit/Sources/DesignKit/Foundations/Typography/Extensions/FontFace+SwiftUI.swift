//
//  FontFace+SwiftUI.swift
//  DesignKit
//
//  Created by Wendra on 28/10/26.
//

import SwiftUI

public extension FontFace {
    /// Font SwiftUI langsung dari PostScript name, tanpa membuat `UIFont` dulu.
    /// `fixedSize` agar tidak ikut Dynamic Type, sama seperti `font(size:)` versi UIKit.
    func swiftUIFont(size: CGFloat) -> Font {
        .custom(postScriptName, fixedSize: size)
    }
}
