//
//  LayoutTolerance.swift
//  DesignKit
//
//  Created by Wendra on 18/10/26.
//

import CoreGraphics

/// Toleransi pembulatan layout, bukan token desain: tidak di-scale dan tidak berasal dari Figma.
public enum LayoutTolerance {
    /// Perbedaan di bawah setengah point dianggap sama (mis. hasil ukur teks, posisi scroll).
    public static let measurement: CGFloat = 0.5
    /// Batas putaran menunggu tinggi baris self-sizing stabil: bidik perkiraan ujung, lalu ujung yang terukur.
    public static let settlingPasses = 4
}
