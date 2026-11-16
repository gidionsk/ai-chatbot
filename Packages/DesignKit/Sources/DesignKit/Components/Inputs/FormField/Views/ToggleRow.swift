//
//  ToggleRow.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI

/// Baris label dengan switch di kanan, mis. "Tampilkan informasi saldo". Warna aktif = warna pilihan terpilih.
/// Nonaktif lewat `.disabled(...)` dari pemakai.
@MainActor
public struct ToggleRow: View {
    @Environment(\.designColors) private var colors
    @Binding private var isOn: Bool
    private let label: String

    public init(label: String, isOn: Binding<Bool>) {
        self.label = label
        self._isOn = isOn
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
                .designFont(.body)
                .foregroundColor(colors.colorsTextPrimaryDark)
                .fixedSize(horizontal: false, vertical: true)
        }
        .tint(colors.colorsSelectionFilledSelected)
    }
}
