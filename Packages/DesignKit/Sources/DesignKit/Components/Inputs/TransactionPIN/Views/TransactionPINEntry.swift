//
//  TransactionPINEntry.swift
//  DesignKit
//
//  Created by Wendra on 16/11/26.
//

import SwiftUI

/// Isi sheet PIN, tanpa service. Input sementara dibersihkan SEBELUM callback enam digit dan saat view ditutup.
/// Caller menonaktifkan keypad selama verifikasi. Copy termasuk label hapus dan progres aksesibilitas dari caller.
/// TODO: Ukuran/padding mengikuti token existing; cocokkan dengan ukuran Figma final bila tersedia.
@MainActor
public struct TransactionPINEntry: View {
    @Environment(\.designColors) private var colors
    @Environment(\.isEnabled) private var isEnabled
    @State private var input = String()
    private let prompt: String
    private let deleteLabel: String
    private let progressLabel: String
    private let error: String?
    private let onComplete: (String) -> Void

    public init(
        prompt: String,
        deleteLabel: String,
        progressLabel: String,
        error: String? = nil,
        onComplete: @escaping (String) -> Void
    ) {
        self.prompt = prompt
        self.deleteLabel = deleteLabel
        self.progressLabel = progressLabel
        self.error = error
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            Text(prompt).designFont(.field)
            Image(systemName: TransactionPINRules.lockSymbol)
                .designFont(.title)
                .accessibilityHidden(true)
            indicators
            if let error {
                Text(error).designFont(.caption).foregroundColor(colors.colorsTextNegative)
            }
            keypad
        }
        .foregroundColor(colors.colorsTextPrimaryDark)
        .padding(FigmaSize.spacingLarge.scaledToArtwork)
        .privacySensitive()
        .onDisappear { input = String() }
        .onChange(of: isEnabled) { if !$0 { input = String() } }
    }

    private var indicators: some View {
        HStack(spacing: FigmaSize.spacingLarge.scaledToArtwork) {
            ForEach(Int.zero..<TransactionPINRules.length, id: \.self) { index in
                Image(systemName: TransactionPINRules.dotSymbol)
                    .foregroundColor(index < input.count ? colors.colorsIconColored : colors.colorsIconDisabled)
            }
        }
        .designFont(.body)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(prompt)
        .accessibilityValue(String(format: progressLabel, input.count, TransactionPINRules.length))
    }

    private var keypad: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: TransactionPINRules.columns),
            spacing: FigmaSize.spacingLarge.scaledToArtwork
        ) {
            ForEach(Array(TransactionPINRules.keys.enumerated()), id: \.offset) { _, key in
                if let key {
                    Button(key) { append(key) }.buttonStyle(PINKeyStyle())
                } else {
                    Color.clear.accessibilityHidden(true)
                }
            }
            Button {
                if !input.isEmpty { input.removeLast() }
            } label: {
                Image(systemName: TransactionPINRules.deleteSymbol)
            }
            .buttonStyle(PINKeyStyle())
            .accessibilityLabel(deleteLabel)
        }
    }
}

// MARK: - Actions

private extension TransactionPINEntry {
    func append(_ key: String) {
        guard isEnabled, input.count < TransactionPINRules.length else { return }
        input += key
        guard input.count == TransactionPINRules.length else { return }
        let completed = input
        input = String()
        onComplete(completed)
    }
}

private struct PINKeyStyle: ButtonStyle {
    @Environment(\.designColors) private var colors
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .designFont(.title)
            .foregroundColor(isEnabled ? colors.colorsTextPrimaryDark : colors.colorsTextDisabled)
            .frame(maxWidth: .infinity)
            .padding(FigmaSize.spacingLarge.scaledToArtwork)
            .background(Circle().fill(configuration.isPressed ? colors.colorsSurfaceDisable : .clear))
            .overlay(
                Circle().strokeBorder(colors.colorsOutlineNetral, lineWidth: FigmaSize.weightOutline.scaledToArtwork)
            )
            .contentShape(Circle())
    }
}
