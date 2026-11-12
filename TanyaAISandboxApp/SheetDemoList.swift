//
//  SheetDemoList.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 12/11/26.
//

import DesignKit
import SwiftUI

/// Sandbox saja: isi contoh bottom sheet (`--sheet-demo`), yaitu judul dan beberapa baris pilihan. Judul dan padding
/// milik isi; wadah sheet hanya memberi permukaan, grabber, cara menutup, dan scroll bila tingginya tetap. Memilih
/// baris menutup sheet.
struct SheetDemoList: View {
    @Environment(\.locale) private var locale
    @Environment(\.designColors) private var colors
    let count: Int
    let onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            title
            ForEach(Int.zero..<count, id: \.self) { _ in
                option
            }
        }
        .padding(.horizontal, FigmaSize.spacingLarge.scaledToArtwork)
        .padding(.bottom, FigmaSize.spacingLarge.scaledToArtwork)
    }

    private var title: some View {
        Text(String(SandboxCopy.sheetTitle, locale: locale))
            .font(FontFace.firaSansSemiBold.swiftUIFont(size: FigmaSize.typographySizeHeadingSmall20.scaledToArtwork))
            .foregroundColor(colors.colorsTextPrimaryDark)
            .padding(.bottom, FigmaSize.spacingMedium.scaledToArtwork)
            .accessibilityAddTraits(.isHeader)
    }

    private var option: some View {
        Button(action: onSelect) {
            Text(String(SandboxCopy.sheetOption, locale: locale))
                .font(
                    FontFace.firaSansRegular.swiftUIFont(size: FigmaSize.typographySizeDisplaySmall14.scaledToArtwork)
                )
                .foregroundColor(colors.colorsTextPrimaryDark)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, FigmaSize.spacingLarge.scaledToArtwork)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(SandboxOptions.sheetOptionIdentifier)
    }
}
