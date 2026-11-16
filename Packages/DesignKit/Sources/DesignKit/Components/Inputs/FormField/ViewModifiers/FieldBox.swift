//
//  FieldBox.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI

/// Kotak isi field: padding dalam di atas permukaan `cardStyle` tanpa bayangan. Nonaktif = latar abu-abu; tidak valid =
/// garis merah. Nonaktif dibaca dari `.disabled(...)` di environment. Modifier sendiri karena warnanya dibaca dari
/// palette di environment. Label dan error milik `FieldFrame`.
/// TODO: Cocokkan padding dan tinggi kotak dengan Figma; sementara dari foto.
struct FieldBox: ViewModifier {
    @Environment(\.designColors) private var colors
    @Environment(\.isEnabled) private var isEnabled
    let isInvalid: Bool

    func body(content: Content) -> some View {
        // Setinggi ikon chevron field pilihan, supaya field teks dan field pilihan sama tinggi.
        content
            .frame(minHeight: FigmaSize.weightIconSmall.scaledToArtwork)
            .padding(FigmaSize.spacingLarge.scaledToArtwork)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle(
                isElevated: false,
                outlineColor: isInvalid ? colors.colorsOutlineRed : CustomColors.Stroke.color,
                fillColor: isEnabled ? nil : colors.colorsSurfaceDisable
            )
    }
}
