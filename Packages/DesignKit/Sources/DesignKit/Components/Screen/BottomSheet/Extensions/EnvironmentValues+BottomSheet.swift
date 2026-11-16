//
//  EnvironmentValues+BottomSheet.swift
//  DesignKit
//
//  Created by Wendra on 14/11/26.
//

import SwiftUI

private struct BottomSheetFooterPlacementKey: EnvironmentKey {
    static let defaultValue = BottomSheetFooterPlacement.inline
}

extension EnvironmentValues {
    /// `.pinned` untuk isi yang sedang berada di dalam `BottomSheet`; dibaca `bottomSheetFooter` untuk tahu footer-nya
    /// ditempel wadah atau tampil biasa di bawah isi.
    var bottomSheetFooterPlacement: BottomSheetFooterPlacement {
        get { self[BottomSheetFooterPlacementKey.self] }
        set { self[BottomSheetFooterPlacementKey.self] = newValue }
    }
}
