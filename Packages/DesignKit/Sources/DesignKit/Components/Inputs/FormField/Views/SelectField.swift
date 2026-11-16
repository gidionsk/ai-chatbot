//
//  SelectField.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI

/// Field pilihan: tampil seperti dropdown dan memanggil `onTap`, biasanya untuk membuka daftar pilihan di bottom sheet.
/// `value` nil = belum dipilih, jadi `placeholder` tampil abu-abu. Teks ringkasan untuk pilihan banyak (mis.
/// "Terpilih 3 rekening") disusun pemakai. `error` tampil merah di bawah kotak. Nonaktif lewat `.disabled(...)`
/// dari pemakai: latar abu-abu dan tidak bisa diketuk.
@MainActor
public struct SelectField: View {
    @Environment(\.designColors) private var colors
    @Environment(\.isEnabled) private var isEnabled
    private let label: String?
    private let value: String?
    private let placeholder: String
    private let error: String?
    private let onTap: () -> Void

    public init(
        label: String? = nil,
        value: String?,
        placeholder: String,
        error: String? = nil,
        onTap: @escaping () -> Void
    ) {
        self.label = label
        self.value = value
        self.placeholder = placeholder
        self.error = error
        self.onTap = onTap
    }

    public var body: some View {
        FieldFrame(label: label, error: error) {
            Button(action: onTap) {
                HStack(spacing: FigmaSize.spacingMedium.scaledToArtwork) {
                    text
                    chevron
                }
                .fieldBox(isInvalid: error != nil)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label ?? placeholder)
            .accessibilityValue(value ?? String())
        }
    }

    private var text: some View {
        Text(value ?? placeholder)
            .designFont(.field)
            .foregroundColor(value == nil ? colors.colorsTextSecondary : colors.colorsTextPrimaryDark)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chevron: some View {
        Image(DesignIcon.chevronDown).resizable().scaledToFit()
            .frame(width: FigmaSize.weightIconSmall.scaledToArtwork, height: FigmaSize.weightIconSmall.scaledToArtwork)
            .foregroundColor(isEnabled ? colors.colorsIconDark : colors.colorsIconDisabled)
            .accessibilityHidden(true)
    }
}
