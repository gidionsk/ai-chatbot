//
//  BottomSheetLayout.swift
//  DesignKit
//
//  Created by Wendra on 14/11/26.
//

import CoreGraphics

/// Letak dan batas tinggi bottom sheet, dihitung dari tinggi layar penuh, safe area, dan keyboard. `keyboardTop` =
/// tepi atas keyboard di koordinat layar; nil selama keyboard tertutup.
struct BottomSheetLayout: Equatable {
    let screenHeight: CGFloat
    let safeAreaTop: CGFloat
    let safeAreaBottom: CGFloat
    let keyboardTop: CGFloat?
    let maxHeight: BottomSheetMaxHeight

    /// Bagian bawah layar yang tertutup keyboard; sheet menempel tepat di atasnya.
    var keyboardHeight: CGFloat {
        guard let keyboardTop else { return .zero }
        return min(max(.zero, screenHeight - keyboardTop), screenHeight)
    }

    /// Jarak isi dari tepi bawah sheet. Selama keyboard tampil, home indicator sudah tertutup keyboard.
    var bottomInset: CGFloat {
        guard keyboardHeight > .zero else { return safeAreaBottom }
        return .zero
    }

    /// Tinggi maksimal sheet termasuk grabber dan `bottomInset`: dari atas keyboard (atau tepi bawah layar) sampai
    /// tepat di bawah status bar, dikurangi `topGap`.
    var sheetMaxHeight: CGFloat {
        let limit = max(.zero, screenHeight - safeAreaTop - topGap - keyboardHeight)
        return maxHeight.resolved(screenHeight: screenHeight, limit: limit)
    }
}

// MARK: - Helpers

private extension BottomSheetLayout {
    /// Layar tanpa notch (mis. iPhone SE): tepat di bawah status bar klasik, tarikan dari grabber masih diambil
    /// Notification Center, jadi sheet berhenti sedikit lebih rendah.
    var topGap: CGFloat {
        guard safeAreaTop > CustomScreenInsets.classicStatusBar else {
            return CustomSizes.BottomSheet.classicTopGap.scaledToArtwork
        }
        return .zero
    }
}
