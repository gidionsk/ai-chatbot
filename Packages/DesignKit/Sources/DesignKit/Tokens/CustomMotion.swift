//
//  CustomMotion.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import Foundation

/// Durasi animasi custom dalam detik. Waktu tidak pernah di-scale, dan pemakainya menghormati Reduce Motion.
public enum CustomMotion {
    /// Bottom sheet naik dari bawah dan latar gelapnya muncul.
    /// TODO: Konfirmasi durasi dengan desain; sementara mengikuti rasa sheet bawaan iOS.
    public static let sheetSlide: TimeInterval = 0.25
    /// Satu titik `TypingDots` dari redup ke terang (bolak-balik terus).
    /// TODO: Konfirmasi durasi dengan desain; belum ada di Figma.
    public static let typingDotPulse: TimeInterval = 0.6
    /// Jeda mulai tiap titik dari kiri; jumlahnya = jumlah titik.
    public static let typingDotDelays: [TimeInterval] = [0, 0.2, 0.4]
}
