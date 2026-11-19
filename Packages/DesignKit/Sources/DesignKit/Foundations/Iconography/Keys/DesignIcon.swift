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
    /// TODO: Ganti PDF dummy dengan aset Figma `icon_arrow` (komponen `auto_scroll`), nama tetap.
    case arrowDown
    /// TODO: Ganti PDF dummy dengan aset Figma panah hapus `Device/Keyboard PIN Custom`, nama tetap.
    case arrowLeft
    case backArrow
    /// TODO: Ganti PDF dummy dengan aset Figma centang pilihan banyak, nama tetap.
    case checkmark
    /// TODO: Ganti PDF dummy dengan aset Figma chevron field pilihan, nama tetap.
    case chevronDown
    case chevronRight
    /// TODO: Ganti PDF dummy dengan aset Figma ikon headset kartu status, nama tetap.
    case headset
    case lightbulb
    /// TODO: Ganti PDF dummy dengan aset Figma gembok sheet PIN (`_Input OTP PIN DEBIT TRANSACTION`), nama tetap.
    case lock
    /// Tanda tambah di tombol lampiran composer (Figma `typing-area` / `add`).
    /// TODO: Ganti PDF dummy dengan aset Figma ikon tambah, nama tetap.
    case plus
    /// TODO: Ganti PDF dummy dengan aset Figma `reply`, nama tetap.
    case reply
    /// Bintang empat sudut di indikator mencari agen (Figma node 3262-86657).
    /// TODO: Ganti PDF dummy dengan aset Figma sparkle, nama tetap.
    case sparkle
}
