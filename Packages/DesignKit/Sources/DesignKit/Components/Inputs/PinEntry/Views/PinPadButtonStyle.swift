//
//  PinPadButtonStyle.swift
//  DesignKit
//
//  Created by Wendra on 16/11/26.
//

import SwiftUI

/// Lingkaran tombol keypad PIN: garis tipis, dan latar abu-abu selama ditekan.
struct PinPadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: keySize, height: keySize)
            .background(Circle().fill(configuration.isPressed ? CustomColors.Keypad.pressedFill : .clear))
            .overlay(Circle().strokeBorder(CustomColors.Keypad.stroke, lineWidth: strokeWidth))
            .contentShape(Circle())
    }

    private var keySize: CGFloat { CustomSizes.PinEntry.keySize.scaledToArtwork }
    private var strokeWidth: CGFloat { CustomSizes.PinEntry.keyStroke.scaledToArtwork }
}
