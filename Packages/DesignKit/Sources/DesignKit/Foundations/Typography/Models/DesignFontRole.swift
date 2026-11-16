//
//  DesignFontRole.swift
//  DesignKit
//
//  Created by Wendra on 14/11/26.
//

import SwiftUI
import UIKit

/// Peran teks DesignKit: pasangan face Fira Sans dan ukuran `FigmaSize` yang dipakai berulang. Komponen memakai
/// `.designFont(role)`, bukan menyusun face dan ukuran sendiri, supaya teks berperan sama tampil sama di semua
/// tempat. Ukurannya tetap (tidak mengikuti Dynamic Type) dan hanya di-scale `.scaledToArtwork`. Peran baru ditambah
/// bila Figma punya pasangan baru, bukan untuk satu pemakai yang kebetulan berbeda.
public enum DesignFontRole: CaseIterable {
    /// Judul besar: judul sheet, sapaan sambutan. SemiBold 20.
    case title
    /// Judul header halaman. Bold 16.
    case headerTitle
    /// Judul kartu atau bagian. SemiBold 16.
    case cardTitle
    /// Isi field form. Regular 16.
    case field
    /// Isi utama: pesan, label, baris pilihan. Regular 14.
    case body
    /// Isi yang ditekankan: judul kartu kecil, teks tombol. SemiBold 14.
    case bodyStrong
    /// Keterangan kecil. Regular 12.
    case caption
    /// Keterangan kecil yang ditekankan: nama pengirim, chip, tombol tautan. SemiBold 12.
    case captionStrong
    /// Catatan kecil miring: gagal kirim, sedang mengetik. Italic 12.
    case captionItalic
}

public extension DesignFontRole {
    var face: FontFace {
        switch self {
        case .title, .cardTitle, .bodyStrong, .captionStrong:
            return .firaSansSemiBold
        case .headerTitle:
            return .firaSansBold
        case .field, .body, .caption:
            return .firaSansRegular
        case .captionItalic:
            return .firaSansItalic
        }
    }

    /// Ukuran Figma sebelum di-scale ke layar.
    var size: CGFloat {
        switch self {
        case .title:
            return FigmaSize.typographySizeHeadingSmall20
        case .headerTitle, .cardTitle, .field:
            return FigmaSize.typographySizeDisplayNormal16
        case .body, .bodyStrong:
            return FigmaSize.typographySizeDisplaySmall14
        case .caption, .captionStrong, .captionItalic:
            return FigmaSize.typographySizeDisplayTiny12
        }
    }

    /// Font SwiftUI berukuran tetap.
    var font: Font { face.swiftUIFont(size: size.scaledToArtwork) }

    /// Versi UIKit, untuk editor yang butuh `UIFont`.
    var uiFont: UIFont { face.font(size: size.scaledToArtwork) }
}
