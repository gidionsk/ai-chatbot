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
    private let attachment: MessageComposerAttachment?
    private let onSend: () -> Void
    private let onStop: () -> Void

    /// `actionLabel` = label aksesibilitas tombol sesuai `action`. `isEnabled` false hanya mengunci tombol;
    /// draft selalu bisa diketik. `attachment` nil = tanpa tombol lampiran.
    public init(
        text: Binding<String>, placeholder: String, actionLabel: String,
        isEnabled: Bool = true, action: MessageComposerAction = .send, fontFace: FontFace = .firaSansRegular,
        attachment: MessageComposerAttachment? = nil, onSend: @escaping () -> Void, onStop: @escaping () -> Void = {}
    ) {
        self._text = text
        self.placeholder = placeholder
        self.actionLabel = actionLabel
        self.isEnabled = isEnabled
        self.action = action
        self.fontFace = fontFace
        self.attachment = attachment
        self.onSend = onSend
        self.onStop = onStop
    }

    /// Tombol lampiran di luar kartu, sejajar bawah dengan tombol kirim: padding vertikalnya sama dengan padding
    /// kartu dan jaraknya ke kartu sama dengan jarak field ke tombol kirim.
    public var body: some View {
        HStack(alignment: .bottom, spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            if let attachment {
                attachmentButton(attachment)
                    .frame(minHeight: singleLineRowHeight)
                    .padding(.vertical, FigmaSize.spacingLarge.scaledToArtwork)
            }
            card
        }
    }

    private var card: some View {
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
                lineSpacing: lineSpacing, accessibilityLabel: placeholder
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

    /// Satu tombol untuk semua fase: kirim atau stop. Ikon berwarna utuh per fase; hanya stopping yang diredupkan
    /// `disabled` bawaan sistem (`.plain`).
    @ViewBuilder
    private var actionButton: some View {
        if action.isSystemDimmed {
            actionButtonBase.buttonStyle(.plain)
        } else {
            actionButtonBase.buttonStyle(ArtworkButtonStyle())
        }
    }

    private var actionButtonBase: some View {
        Button(action: tapAction) {
            Image(action.icon(isEnabled: isActionEnabled)).resizable().scaledToFit()
                .frame(
                    width: CustomSizes.Composer.sendButton.scaledToArtwork,
                    height: CustomSizes.Composer.sendButton.scaledToArtwork
                )
                .contentShape(Rectangle())
        }
        .disabled(!isActionEnabled)
        .accessibilityLabel(actionLabel)
        .accessibilityIdentifier(ComponentIdentifier.Composer.send)
    }

    private func attachmentButton(_ attachment: MessageComposerAttachment) -> some View {
        Button(action: attachment.onTap) {
            Image(DesignColorIcon.attachment).resizable().scaledToFit()
                .frame(
                    width: CustomSizes.Composer.sendButton.scaledToArtwork,
                    height: CustomSizes.Composer.sendButton.scaledToArtwork
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(ArtworkButtonStyle())
        .accessibilityLabel(attachment.label)
        .accessibilityIdentifier(ComponentIdentifier.Composer.attachment)
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

    var isActionEnabled: Bool {
        switch action {
        case .send:
            return isEnabled && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .stop:
            return isEnabled
        case .stopping:
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
