//
//  DateChipStyle.swift
//  DesignKit
//
//  Created by Wendra on 18/11/26.
//

/// Tampilan `DateChip`. Ukuran dan padding sama; hanya permukaan dan warna teks yang berbeda.
public enum DateChipStyle {
    /// Permukaan kartu tanpa bayangan dengan teks sekunder, untuk label tanggal.
    case card
    /// Figma `time_stamp`: latar N600 Black - Medium dengan teks putih, seluruh chip ber-opacity 70%. Untuk status
    /// di antara pesan, mis. awal dan akhir sesi.
    case filled
}
