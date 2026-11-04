//
//  CustomTextLines.swift
//  DesignKit
//
//  Created by Wendra on 18/10/26.
//

/// Batas jumlah baris per peran teks. Jumlah baris tidak pernah di-scale.
/// Ubah di sini agar semua layar dengan peran yang sama ikut berubah.
public enum CustomTextLines {
    /// Editor composer tumbuh dari satu sampai empat baris, lalu scroll di dalam field.
    public static let composerInput = 1...4
    public static let headerTitle = 1
    public static let dateChip = 1
}
