//
//  FontFace.swift
//  DesignKit
//
//  Created by Wendra on 15/10/26.
//

import UIKit

/// Face Fira Sans di bundle. Nama file resource dan nama PostScript adalah metadata font yang berbeda.
public enum FontFace: String, CaseIterable {
    case firaSansRegular = "FiraSans-Regular.ttf"
    case firaSansMedium = "FiraSans-Medium.ttf"
    case firaSansSemiBold = "FiraSans-SemiBold.ttf"
    case firaSansBold = "FiraSans-Bold.ttf"
    case firaSansItalic = "FiraSans-Italic.ttf"
    case firaSansBoldItalic = "FiraSans-BoldItalic.ttf"

    private static let directoryName = "Fonts"

    public var postScriptName: String {
        switch self {
        case .firaSansRegular: return "FiraSans-Regular"
        case .firaSansMedium: return "FiraSans-Medium"
        case .firaSansSemiBold: return "FiraSans-SemiBold"
        case .firaSansBold: return "FiraSans-Bold"
        case .firaSansItalic: return "FiraSans-Italic"
        case .firaSansBoldItalic: return "FiraSans-BoldItalic"
        }
    }

    public func font(size: CGFloat) -> UIFont {
        UIFont(name: postScriptName, size: size) ?? UIFont.systemFont(ofSize: size)
    }

    /// Panggil saat bootstrap sebelum menampilkan komponen; registrasi berlaku satu proses dan boleh diulang.
    public static func registerFonts() throws {
        _ = try FontLoader.register(
            fileNames: allCases.map(\.rawValue), bundle: .module, subdirectory: directoryName
        )
    }
}
