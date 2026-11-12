//
//  FormToggle.swift
//  DesignKit
//

import SwiftUI

/// A reusable form row with a compact 48 x 24 point switch.
@MainActor
public struct FormToggle: View {
    @Environment(\.designColors) private var colors

    private let title: String
    private let isEnabled: Bool
    @Binding private var isOn: Bool

    public init(title: String, isOn: Binding<Bool>, isEnabled: Bool = true) {
        self.title = title
        self._isOn = isOn
        self.isEnabled = isEnabled
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(FontFace.firaSansSemiBold.swiftUIFont(
                    size: FigmaSize.typographySizeDisplayTiny12.scaledToArtwork
                ))
                .foregroundColor(isEnabled ? colors.colorsTextPrimaryDark : colors.colorsTextDisabled)
        }
        .toggleStyle(FormSwitchStyle(
            selectedColor: colors.colorsSelectionFilledSelected,
            unselectedColor: colors.colorsSelectionEmptyDefault,
            disabledColor: colors.colorsSelectionFilledDisable,
            isEnabled: isEnabled
        ))
        .disabled(!isEnabled)
    }
}

private struct FormSwitchStyle: ToggleStyle {
    let selectedColor: Color
    let unselectedColor: Color
    let disabledColor: Color
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.label
            Spacer(minLength: 8)
            Capsule()
                .fill(isEnabled
                    ? (configuration.isOn ? selectedColor : unselectedColor)
                    : disabledColor)
                .frame(width: 48, height: 24)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 18, height: 18)
                        .padding(3)
                }
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard isEnabled else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                configuration.isOn.toggle()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isEnabled ? .isButton : [])
        .accessibilityValue(configuration.isOn ? "On" : "Off")
    }
}
