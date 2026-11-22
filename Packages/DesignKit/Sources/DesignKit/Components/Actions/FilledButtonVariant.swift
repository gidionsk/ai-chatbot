//
//  FilledButtonVariant.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

/// Ukuran, gaya teks, dan permukaan `FilledButton`.
public enum FilledButtonVariant: Equatable {
    /// Aksi utama, mis. Konfirmasi di form atau Pilih di daftar pilihan banyak.
    case regular
    /// Aksi kedua di samping aksi utama, mis. Batalkan di form: ukuran sama dengan `.regular`, tanpa latar gelap,
    /// hanya garis tepi dan teks berwarna tombol.
    case outlined
    /// Teks kecil bergaris bawah untuk aksi ringan di bawah konten.
    case link
}
