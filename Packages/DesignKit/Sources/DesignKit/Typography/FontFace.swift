//
//  FontFace.swift
//  DesignKit
//
//  Created by Wendra on 15/10/26.
//

import UIKit

/// Resource filenames and PostScript names are separate font metadata.
public enum FontFace: String, CaseIterable {
    case firaSansRegular = "FiraSans-Regular.ttf"
    case firaSansMedium = "FiraSans-Medium.ttf"
    case firaSansSemiBold = "FiraSans-SemiBold.ttf"
    case firaSansBold = "FiraSans-Bold.ttf"
    case firaSansItalic = "FiraSans-Italic.ttf"
    case firaSansBoldItalic = "FiraSans-BoldItalic.ttf"
    case openSansRegular = "OpenSans-Regular.ttf"
    case openSansMedium = "OpenSans-Medium.ttf"
    case openSansBold = "OpenSans-Bold.ttf"

    private static let directoryName = "Fonts"

    public var postScriptName: String {
        switch self {
        case .firaSansRegular: return "FiraSans-Regular"
        case .firaSansMedium: return "FiraSans-Medium"
        case .firaSansSemiBold: return "FiraSans-SemiBold"
        case .firaSansBold: return "FiraSans-Bold"
        case .firaSansItalic: return "FiraSans-Italic"
        case .firaSansBoldItalic: return "FiraSans-BoldItalic"
        case .openSansRegular: return "OpenSansRoman-Regular"
        case .openSansMedium: return "OpenSansRoman-Medium"
        case .openSansBold: return "OpenSans-Bold"
        }
    }

    public func font(size: CGFloat) -> UIFont {
        UIFont(name: postScriptName, size: size) ?? UIFont.systemFont(ofSize: size)
    }

    /// Call during bootstrap before presenting components; registration is process-scoped and idempotent.
    public static func registerFonts() throws {
        _ = try FontLoader.register(
            fileNames: allCases.map(\.rawValue), bundle: .module, subdirectory: directoryName
        )
    }
}
