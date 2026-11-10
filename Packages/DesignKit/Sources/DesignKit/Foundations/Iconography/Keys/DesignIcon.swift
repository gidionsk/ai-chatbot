//
//  DesignIcon.swift
//  DesignKit
//
//  Created by Wendra on 27/10/26.
//

/// Ikon template di `Assets.xcassets` DesignKit (24×24, diwarnai lewat `foregroundColor`).
/// Nama case sama persis dengan nama imageset, jadi menambah ikon cukup menambah case;
/// `AssetTests` memastikan setiap case ada di bundle dan setiap imageset punya case.
/// Ikon berwarna utuh ada di `DesignColorIcon`; gambar non-ikon (ilustrasi, latar) dibuat enum terpisah karena
/// sifatnya berbeda.
public enum DesignIcon: String, CaseIterable {
    case backArrow
    case chevronRight
    case lightbulb
    case moreMenu
    /// TODO: Ganti PDF dummy dengan aset Figma `reply`, nama tetap.
    case reply
}
