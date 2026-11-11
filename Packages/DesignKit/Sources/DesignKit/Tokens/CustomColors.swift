//
//  CustomColors.swift
//  DesignKit
//
//  Created by Wendra on 15/10/26.
//

import SwiftUI

/// Semantic uses of additional colors. Generated colors remain the source for existing roles.
public enum CustomColors {
    public enum Stroke {
        public static let color = CustomBasePaletteColor.royalPastelBlue
        /// Figma N400 Gray - Primary, untuk chip yang bisa diketuk.
        public static let strong = CustomBasePaletteColor.glossySilver
    }

    public enum Button {
        /// Figma tombol batal di bawah kartu status.
        public static let muted = CustomBasePaletteColor.slateBlue
    }

    public enum Shadow {
        public static let opacity: Double = 0.4
        public static let color = CustomBasePaletteColor.glossySilver.opacity(opacity)
        /// Figma `auto_scroll`: `#BEC3D0` 80%, untuk tombol yang mengambang di atas konten.
        public static let strongOpacity: Double = 0.8
        public static let strong = CustomBasePaletteColor.glossySilver.opacity(strongOpacity)
    }
}
