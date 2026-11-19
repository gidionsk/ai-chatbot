//
//  CustomColors.swift
//  DesignKit
//
//  Created by Wendra on 15/10/26.
//

import SwiftUI

/// Semantic uses of additional colors. Generated colors remain the source for existing roles.
public enum CustomColors {
    /// Opacity penuh, untuk view yang tampil lagi setelah disembunyikan dengan opacity `.zero`.
    public static let opaque: Double = 1

    public enum Stroke {
        public static let color = CustomBasePaletteColor.royalPastelBlue
        /// Figma N400 Gray - Primary, untuk chip yang bisa diketuk.
        public static let strong = CustomBasePaletteColor.glossySilver
    }

    /// Tombol keypad `PinEntry`: garis Figma N200 Gray - Blush, dan latar saat ditekan.
    /// TODO: Konfirmasi warna tombol yang sedang ditekan dengan Figma; sementara dari foto.
    public enum Keypad {
        public static let stroke = CustomBasePaletteColor.royalPastelBlue
        public static let pressedFill = CustomBasePaletteColor.glossySilver
    }

    public enum Chip {
        /// Figma `time_stamp`: opacity seluruh chip berlatar abu, termasuk teksnya.
        public static let filledOpacity: Double = 0.7
    }

    /// TODO: Konfirmasi dengan Figma; belum ada desain titik menunggu jawaban.
    public enum TypingDots {
        /// Opacity titik saat redup; terang = `opaque`.
        public static let dimmedOpacity: Double = 0.3
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

    /// Latar gelap di belakang bottom sheet; warnanya `colorsSurfaceOverlay24` dari palette.
    /// TODO: Konfirmasi opacity dengan Figma; sementara estimasi dari foto.
    public enum Scrim {
        public static let opacity: Double = 0.6
    }
}
