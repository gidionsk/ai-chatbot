//
//  DesignColorIcon.swift
//  DesignKit
//
//  Created by Wendra on 3/11/26.
//

/// Ikon berwarna utuh di `Assets.xcassets` DesignKit (24×24, render original, tidak di-tint).
/// Nama imageset mengikuti aset host Byon agar bisa disalin apa adanya; `AssetTests` menjaga kecocokannya.
/// TODO: Ganti PDF dummy dengan aset Figma, nama tetap.
public enum DesignColorIcon: String, CaseIterable {
    /// Tombol kirim aktif.
    case sendOn = "send-on"
    /// Tombol kirim nonaktif (draft kosong atau belum siap).
    case sendOff = "send-off"
    /// Tombol stop jawaban.
    case sendPause = "send-pause"
}
