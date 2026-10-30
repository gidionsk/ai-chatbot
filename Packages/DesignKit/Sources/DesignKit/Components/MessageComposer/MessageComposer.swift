//
//  MessageComposer.swift
//  DesignKit
//
//  Created by Wendra on 15/10/26.
//

import SwiftUI

/// Inner spacing and appearance belong here; the screen owns outer margins.
@MainActor
public struct MessageComposer: View {
    @Environment(\.designColors)
    private var colors
    @Binding
    private var text: String
    // Figma typography follows artwork scaling only, independent of the user's text size setting.
    private let fontSize = FigmaSize.typographySizeDisplaySmall14.scaledToArtwork
    private let placeholder: String
    private let actionLabel: String
    private let isEnabled: Bool
    private let action: MessageComposerAction
    private let fontFace: FontFace
    private let onSend: () -> Void
    private let onStop: () -> Void

    /// `actionLabel` = label aksesibilitas tombol sesuai `action`. `isEnabled` false hanya mengunci tombol
    /// kirim; draft tetap bisa diketik kecuali selama `.loading`.
    public init(
        text: Binding<String>, placeholder: String, actionLabel: String,
        isEnabled: Bool = true, action: MessageComposerAction = .send, fontFace: FontFace = .openSansRegular,
        onSend: @escaping () -> Void, onStop: @escaping () -> Void = {}
    ) {
        self._text = text
        self.placeholder = placeholder
        self.actionLabel = actionLabel
        self.isEnabled = isEnabled
        self.action = action
        self.fontFace = fontFace
        self.onSend = onSend
        self.onStop = onStop
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            field
                .frame(minHeight: singleLineRowHeight)
            actionButton
                .frame(minHeight: singleLineRowHeight)
        }
        .padding(FigmaSize.spacingLarge.scaledToArtwork)
        .cardStyle()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(ComponentIdentifier.Composer.root)
    }

    private var field: some View {
        ZStack(alignment: .leading) {
            GrowingTextInput(
                text: $text, font: inputFont, textColor: UIColor(colors.colorsTextPrimaryDark),
                lineSpacing: lineSpacing, isEditable: action != .loading, accessibilityLabel: placeholder
            )
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier(ComponentIdentifier.Composer.input)
            if text.isEmpty {
                Text(placeholder)
                    .font(Font(inputFont))
                    .lineLimit(CustomTextLines.composerInput.lowerBound)
                    .foregroundColor(colors.colorsTextSecondary)
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)
            }
        }
    }

    /// Satu tombol untuk semua fase: kirim, titik bergerak (terkunci), atau stop.
    private var actionButton: some View {
        Button(action: tapAction) {
            actionIcon
                .frame(
                    width: CustomSizes.Composer.sendButton.scaledToArtwork,
                    height: CustomSizes.Composer.sendButton.scaledToArtwork
                )
                .background(Circle().fill(buttonFill))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isActionEnabled)
        .accessibilityLabel(actionLabel)
        .accessibilityIdentifier(ComponentIdentifier.Composer.send)
    }

    @ViewBuilder
    private var actionIcon: some View {
        switch action {
        case .send:
            icon(DesignIcon.sendArrow)
        case .loading:
            LoadingDots(color: colors.colorsIconLight)
        case .stop, .stopping:
            icon(DesignIcon.stop)
        }
    }

    private func icon(_ name: DesignIcon) -> some View {
        Image(name).resizable().scaledToFit()
            .padding(CustomSizes.Composer.sendIconInset.scaledToArtwork)
            .foregroundColor(colors.colorsIconLight)
    }
}

// MARK: - Helpers

private extension MessageComposer {
    var inputFont: UIFont { fontFace.font(size: fontSize) }

    /// Equal single-line rows center the field/button; a taller field keeps the button at its bottom.
    var singleLineRowHeight: CGFloat {
        max(CustomSizes.Composer.sendButton.scaledToArtwork, ceil(inputFont.lineHeight + lineSpacing))
    }

    var lineSpacing: CGFloat {
        let leading = FigmaSize.typographyLineHeightDisplaySmall14.scaledToArtwork
        return max(.zero, leading - inputFont.lineHeight)
    }

    /// Merah saat bisa ditekan atau sedang memuat; abu-abu saat draft kosong, nonaktif, atau stop diproses.
    var buttonFill: Color {
        isActionEnabled || action == .loading ? colors.colorsButtonActive : colors.colorsIconDisabled
    }

    var isActionEnabled: Bool {
        switch action {
        case .send:
            return isEnabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .stop:
            return isEnabled
        case .loading, .stopping:
            return false
        }
    }

    func tapAction() {
        if action == .stop {
            onStop()
        } else {
            onSend()
        }
    }
}
