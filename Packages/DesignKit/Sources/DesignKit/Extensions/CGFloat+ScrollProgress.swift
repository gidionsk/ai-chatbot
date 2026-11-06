//
//  CGFloat+ScrollProgress.swift
//  DesignKit
//
//  Created by Wendra on 5/11/26.
//

import CoreGraphics

public extension CGFloat {
    /// Seberapa jauh konten digulir dari posisi teratas: 0 di atas (termasuk tarikan bounce), naik sebanding `offset`,
    /// dan berhenti di 1 setelah `distance`. Offset di bawah `threshold` dianggap masih di atas.
    static func scrollProgress(
        offset: CGFloat, distance: CGFloat, threshold: CGFloat = LayoutTolerance.measurement
    ) -> CGFloat {
        // Jarak minimal setengah point agar pembagian aman walau caller memberi nol.
        let span = Swift.max(distance, LayoutTolerance.measurement)
        guard offset >= Swift.max(.zero, threshold) else { return .zero }
        return Swift.min(offset, span) / span
    }
}
