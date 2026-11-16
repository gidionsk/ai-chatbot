//
//  BottomSheetFooterKey.swift
//  DesignKit
//
//  Created by Wendra on 14/11/26.
//

import SwiftUI

/// Footer yang dititipkan isi sheet lewat `bottomSheetFooter`, untuk ditempel `BottomSheet` di tepi bawahnya. Nil =
/// isi tidak punya footer.
struct BottomSheetFooterKey: PreferenceKey {
    static var defaultValue: AnyView? { nil }

    static func reduce(value: inout AnyView?, nextValue: () -> AnyView?) {
        value = nextValue() ?? value
    }
}
