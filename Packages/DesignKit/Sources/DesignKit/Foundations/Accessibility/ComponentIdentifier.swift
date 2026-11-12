//
//  ComponentIdentifier.swift
//  DesignKit
//
//  Created by Wendra on 15/10/26.
//

/// Identifier teknis untuk UI test, dikelompokkan per komponen seperti `CustomSizes`.
/// Nilainya kontrak dengan UI test; ubah hanya bersama test yang memakainya.
enum ComponentIdentifier {
    enum Header {
        static let root = "header"
        static let scrolled = "header.scrolled"
        static let title = "header.title"
        static let back = "header.back"
    }

    enum BottomSheet {
        static let root = "sheet"
        static let handle = "sheet.handle"
    }

    enum Composer {
        static let root = "composer"
        static let input = "composer.input"
        static let send = "composer.send"
        static let attachment = "composer.attachment"
    }
}
