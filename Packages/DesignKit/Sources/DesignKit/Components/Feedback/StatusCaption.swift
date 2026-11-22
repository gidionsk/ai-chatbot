//
//  StatusCaption.swift
//  DesignKit
//
//  Created by Wendra on 19/11/26.
//

import SwiftUI

/// Status singkat di bawah pesan terakhir, mis. sedang mengetik: teks kecil abu-abu selebar wadah. Copy dari pemakai.
/// TODO: Konfirmasi ukuran dan warna teks dengan Figma node 3262-86657.
@MainActor
public struct StatusCaption: View {
    @Environment(\.designColors) private var colors
    private let text: String
    private let isItalic: Bool

    public init(text: String, isItalic: Bool = false) {
        self.text = text
        self.isItalic = isItalic
    }

    public var body: some View {
        Text(text)
            .designFont(isItalic ? .captionItalic : .caption)
            .foregroundColor(colors.colorsTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
