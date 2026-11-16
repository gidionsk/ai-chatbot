//
//  BottomSheetFooterPlacement.swift
//  DesignKit
//
//  Created by Wendra on 14/11/26.
//

/// Tempat footer dari `bottomSheetFooter` digambar.
enum BottomSheetFooterPlacement {
    /// Di luar bottom sheet (mis. katalog): biasa, di bawah isi.
    case inline
    /// Di dalam `BottomSheet`: ditempel wadah di tepi bawahnya, tidak ikut ter-scroll.
    case pinned
}
