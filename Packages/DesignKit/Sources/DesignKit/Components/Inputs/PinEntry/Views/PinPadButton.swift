//
//  PinPadButton.swift
//  DesignKit
//
//  Created by Wendra on 16/11/26.
//

import SwiftUI

/// Satu tombol keypad PIN: lingkaran bergaris berisi angka, atau panah hapus dengan label aksesibilitas dari pemakai.
/// Nonaktif lewat `.disabled(...)` dari pemakai.
@MainActor
struct PinPadButton: View {
    @Environment(\.designColors) private var colors
    @Environment(\.isEnabled) private var isEnabled
    let key: PinPadKey
    let deleteLabel: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) { face }
            .buttonStyle(PinPadButtonStyle())
            .accessibilityIdentifier(identifier)
    }

    @ViewBuilder
    private var face: some View {
        switch key {
        case .digit(let digit):
            Text(String(digit))
                .designFont(.keypadDigit)
                .foregroundColor(isEnabled ? colors.colorsTextPrimaryDark : colors.colorsTextDisabled)
        case .delete:
            Image(DesignIcon.arrowLeft)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(isEnabled ? colors.colorsIconDark : colors.colorsIconDisabled)
                .accessibilityLabel(deleteLabel)
        }
    }
}

// MARK: - Helpers

private extension PinPadButton {
    var iconSize: CGFloat { FigmaSize.unitDefault.scaledToArtwork }

    var identifier: String {
        switch key {
        case .digit(let digit):
            return ComponentIdentifier.PinEntry.digit(digit)
        case .delete:
            return ComponentIdentifier.PinEntry.delete
        }
    }
}
