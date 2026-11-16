//
//  FieldFrame.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI

/// Susunan satu field form: label di atas, isi field, lalu pesan error merah di bawah bila ada. Dipakai bersama
/// `SelectField` dan `TextInputField` supaya jaraknya sama.
@MainActor
struct FieldFrame<Content: View>: View {
    @Environment(\.designColors) private var colors
    private let label: String?
    private let error: String?
    private let content: Content

    init(label: String?, error: String?, @ViewBuilder content: () -> Content) {
        self.label = label
        self.error = error
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaSize.spacingMedium.scaledToArtwork) {
            title
            content
            message
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var title: some View {
        if let label {
            Text(label)
                .designFont(.body)
                .foregroundColor(colors.colorsTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var message: some View {
        if let error {
            Text(error)
                .designFont(.caption)
                .foregroundColor(colors.colorsTextNegative)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
