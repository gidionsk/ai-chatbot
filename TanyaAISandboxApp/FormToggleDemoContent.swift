//
//  FormToggleDemoContent.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 12/11/26.
//

import DesignKit
import SwiftUI

/// Fixture sandbox untuk binding dua arah dan disabled lokal/parent; dibuka dengan --form-toggle-demo.
@MainActor
struct FormToggleDemoContent: View {
    @Environment(\.locale) private var locale
    @State private var isOn = false
    @State private var isLocallyEnabled = true
    @State private var isFormEnabled = true

    var body: some View {
        VStack(spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            VStack {
                FormToggle(
                    title: String(SandboxCopy.toggleTitle, locale: locale),
                    isOn: $isOn,
                    isEnabled: isLocallyEnabled
                )
                .accessibilityIdentifier(SandboxOptions.formToggleIdentifier)
            }
            .disabled(!isFormEnabled)
            Text(String(isOn ? SandboxCopy.toggleOn : SandboxCopy.toggleOff, locale: locale))
                .accessibilityIdentifier(SandboxOptions.formToggleValueIdentifier)
            Button(String(SandboxCopy.toggleChangeValue, locale: locale)) { isOn.toggle() }
                .accessibilityIdentifier(SandboxOptions.formToggleChangeIdentifier)
            Toggle(String(SandboxCopy.toggleEnabled, locale: locale), isOn: $isLocallyEnabled)
                .toggleStyle(.switch)
                .accessibilityIdentifier(SandboxOptions.formToggleEnabledIdentifier)
            Toggle(String(SandboxCopy.toggleFormEnabled, locale: locale), isOn: $isFormEnabled)
                .toggleStyle(.switch)
                .accessibilityIdentifier(SandboxOptions.formToggleParentIdentifier)
        }
        .font(FontFace.firaSansRegular.swiftUIFont(size: FigmaSize.typographySizeDisplaySmall14.scaledToArtwork))
        .padding(FigmaSize.spacingLarge.scaledToArtwork)
    }
}
