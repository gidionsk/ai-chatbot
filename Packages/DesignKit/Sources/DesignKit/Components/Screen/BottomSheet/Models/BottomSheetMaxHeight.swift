//
//  BottomSheetMaxHeight.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import CoreGraphics

/// Batas tinggi bottom sheet. Sheet tetap setinggi isinya; hanya isi yang lebih panjang dari batas yang membuat sheet
/// berhenti di batas itu dan isinya di-scroll.
public enum BottomSheetMaxHeight: Equatable {
    /// Bawaan: sampai tepat di bawah status bar, tidak pernah layar penuh.
    case belowStatusBar
    /// Sekian bagian dari tinggi layar penuh, mis. `0.6` = 60%; tidak pernah melewati batas bawaan.
    case screenFraction(CGFloat)

    /// Tinggi maksimal sheet termasuk grabber dan safe area bawah. `limit` = dari tepi bawah layar sampai tepat di
    /// bawah status bar.
    func resolved(screenHeight: CGFloat, limit: CGFloat) -> CGFloat {
        guard case .screenFraction(let fraction) = self else { return limit }
        return min(max(.zero, screenHeight * fraction), limit)
    }
}
