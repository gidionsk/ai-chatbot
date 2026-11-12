//
//  FormToggle.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI

/// Baris form umum dengan switch 48 × 24 pada artwork. Copy dan state dimiliki pemakai.
/// TODO: Konfirmasi tipografi label dan jarak minimum dengan Figma; mempertahankan pilihan awal PR #63.
@MainActor
public struct FormToggle: View {
    @Environment(\.designColors) private var colors
    @Environment(\.isEnabled) private var isEnvironmentEnabled
    @Binding private var isOn: Bool
    private let title: String
    private let isEnabled: Bool

    public init(title: String, isOn: Binding<Bool>, isEnabled: Bool = true) {
        self.title = title
        self._isOn = isOn
        self.isEnabled = isEnabled
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(
                    FontFace.firaSansSemiBold.swiftUIFont(size: FigmaSize.typographySizeDisplayTiny12.scaledToArtwork)
                )
                .foregroundColor(isInteractionEnabled ? colors.colorsTextPrimaryDark : colors.colorsTextDisabled)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .toggleStyle(FormSwitchStyle())
        .disabled(!isEnabled)
    }
}

// MARK: - Helpers

private extension FormToggle {
    var isInteractionEnabled: Bool { isEnabled && isEnvironmentEnabled }
}

@MainActor
private struct FormSwitchStyle: ToggleStyle {
    @Environment(\.designColors) private var colors
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        Button {
            guard isEnabled else { return }
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: .zero) {
                configuration.label
                // Mempertahankan jarak minimum awal: dua sela 12 dan spacer 8 pada artwork.
                Spacer(minLength: FigmaSize.spacingExtraLarge.scaledToArtwork)
                Capsule()
                    .fill(trackColor(isOn: configuration.isOn))
                    .frame(
                        width: CustomSizes.FormToggle.width.scaledToArtwork,
                        height: CustomSizes.FormToggle.height.scaledToArtwork
                    )
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Circle()
                            .fill(colors.colorsSurfacePrimary)
                            .frame(
                                width: CustomSizes.FormToggle.thumbSize.scaledToArtwork,
                                height: CustomSizes.FormToggle.thumbSize.scaledToArtwork
                            )
                            .padding(CustomSizes.FormToggle.thumbInset.scaledToArtwork)
                    }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
                .disabled(!isEnabled)
        }
    }
}

// MARK: - Helpers

private extension FormSwitchStyle {
    func trackColor(isOn: Bool) -> Color {
        if isEnabled {
            return isOn ? colors.colorsSelectionFilledSelected : colors.colorsSelectionEmptyDefault
        }
        return isOn ? colors.colorsSelectionFilledDisable : colors.colorsSelectionEmptyDisable
    }
}
