//
//  EnabledProbe.swift
//  DesignKitTests
//
//  Created by Wendra on 15/11/26.
//

import SwiftUI

/// Melaporkan `isEnabled` dari environment tempat view ini digambar, setiap kali tampil.
struct EnabledProbe: View {
    @Environment(\.isEnabled) private var isEnabled
    let onAppear: (Bool) -> Void

    var body: some View {
        Color.clear.onAppear { onAppear(isEnabled) }
    }
}
