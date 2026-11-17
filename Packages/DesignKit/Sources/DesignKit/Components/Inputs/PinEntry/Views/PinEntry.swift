//
//  PinEntry.swift
//  DesignKit
//
//  Created by Wendra on 16/11/26.
//

import SwiftUI

/// Isi bottom sheet untuk memasukkan PIN: judul, gembok, titik per digit, `error` merah di bawahnya, lalu keypad
/// lingkaran 3×4.
/// Tidak memakai keyboard sistem. PIN dipegang pemakai lewat `pin`; begitu sepanjang `length` (aturan host, mis. 6),
/// `onComplete` dipanggil
/// sekali dengan PIN itu. Komponen tidak menyimpan, menampilkan, atau me-log angkanya. Pemakai yang memeriksa PIN
/// (service host), menonaktifkan keypad selama memeriksa lewat `.disabled(...)`, dan mengosongkan `pin` sambil mengisi
/// `error` bila PIN salah. Padding isi milik komponen ini, wadah sheet hanya memberi permukaan.
/// Ukuran dari Figma `_Input OTP PIN DEBIT TRANSACTION` dan `Device/Keyboard PIN Custom`; beberapa jarak diukur dari
/// foto (lihat `CustomSizes.PinEntry`).
@MainActor
public struct PinEntry: View {
    @Environment(\.designColors) private var colors
    @Binding private var pin: String
    private let title: String
    private let length: Int
    private let error: String?
    private let deleteLabel: String
    private let onComplete: (String) -> Void

    /// `deleteLabel` = label aksesibilitas tombol hapus, dari copy pemakai.
    public init(
        title: String,
        pin: Binding<String>,
        length: Int,
        error: String? = nil,
        deleteLabel: String,
        onComplete: @escaping (String) -> Void
    ) {
        self.title = title
        self._pin = pin
        self.length = length
        self.error = error
        self.deleteLabel = deleteLabel
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: .zero) {
            heading
            lockIcon
            dotContainer
            keypad
        }
        .frame(maxWidth: .infinity)
        .padding(.top, FigmaSize.spacingLarge.scaledToArtwork)
        .padding(.horizontal, CustomSizes.PinEntry.padding.scaledToArtwork)
        .padding(.bottom, FigmaSize.spacingLarge.scaledToArtwork)
    }

    /// Figma `Regular 16`, rata tengah; bagi VoiceOver judul dibacakan sebagai label titik PIN.
    private var heading: some View {
        Text(title)
            .designFont(.field)
            .foregroundColor(colors.colorsTextPrimaryDark)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, FigmaSize.spacingDoubleExtraLarge.scaledToArtwork)
            .accessibilityHidden(true)
    }

    private var lockIcon: some View {
        Image(DesignIcon.lock)
            .resizable()
            .scaledToFit()
            .frame(
                width: CustomSizes.PinEntry.lockSize.scaledToArtwork,
                height: CustomSizes.PinEntry.lockSize.scaledToArtwork
            )
            .foregroundColor(colors.colorsIconDark)
            .padding(.bottom, FigmaSize.spacingDoubleExtraLarge.scaledToArtwork)
            .accessibilityHidden(true)
    }

    /// Titik PIN dengan `error` tepat di bawahnya.
    private var dotContainer: some View {
        VStack(spacing: FigmaSize.spacingSmall.scaledToArtwork) {
            PinDots(
                label: title,
                filledCount: pin.count,
                length: length
            )
            errorText
        }
        .padding(.bottom, FigmaSize.spacingExtraLarge.scaledToArtwork)
    }

    /// Tempatnya selalu setinggi satu baris, supaya keypad tidak bergeser saat error muncul atau hilang.
    private var errorText: some View {
        Text(error ?? String())
            .designFont(.caption)
            .foregroundColor(colors.colorsTextNegative)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: FigmaSize.typographyLineHeightDisplayTiny12.scaledToArtwork)
            .accessibilityHidden(error == nil)
            .accessibilityIdentifier(ComponentIdentifier.PinEntry.error)
    }

    /// Tombol tiap baris dibagi rata selebar sheet: `Spacer` di kiri, di antara, dan di kanan tombol.
    private var keypad: some View {
        VStack(spacing: CustomSizes.PinEntry.padding.scaledToArtwork) {
            ForEach(PinPadKey.rows.indices, id: \.self) { row in
                HStack(spacing: .zero) {
                    Spacer()
                    ForEach(PinPadKey.rows[row].indices, id: \.self) { column in
                        slot(PinPadKey.rows[row][column])
                        Spacer()
                    }
                }
            }
        }
    }
}

// MARK: - Helpers

private extension PinEntry {
    @ViewBuilder
    func slot(_ key: PinPadKey?) -> some View {
        if let key {
            PinPadButton(key: key, deleteLabel: deleteLabel) { press(key) }
        } else {
            let keySize = CustomSizes.PinEntry.keySize.scaledToArtwork
            Color.clear
                .frame(width: keySize, height: keySize)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Actions

private extension PinEntry {
    func press(_ key: PinPadKey) {
        let updated = key.applied(to: pin, length: length)
        guard updated != pin else { return }
        pin = updated
        guard updated.count == length else { return }
        onComplete(updated)
    }
}
