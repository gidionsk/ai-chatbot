//
//  ScreenViewport.swift
//  DesignKit
//
//  Created by Wendra on 5/11/26.
//

import CoreGraphics

/// Area scroll `ScreenContainer` untuk konten yang mengatur posisinya sendiri.
public struct ScreenViewport: Equatable {
    /// Tinggi area scroll saat ini, ikut mengecil saat keyboard terbuka.
    public let height: CGFloat
    /// Tinggi header yang menimpa tepi atas area scroll.
    public let headerHeight: CGFloat
    /// True bila posisi scroll dekat ujung konten.
    public let isNearBottom: Bool

    public init(height: CGFloat = .zero, headerHeight: CGFloat = .zero, isNearBottom: Bool = true) {
        self.height = height
        self.headerHeight = headerHeight
        self.isNearBottom = isNearBottom
    }
}
