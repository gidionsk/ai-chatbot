//
//  ChatSheet.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

/// Bottom sheet yang sedang tampil di halaman chat; satu pemasangan `.bottomSheet(item:)` untuk semua jenisnya. Nilai
/// lain membangun sheet baru seutuhnya.
enum ChatSheet: Hashable {
    /// Pilihan Galeri / File. `isFormatRejected` = dibuka lagi tepat setelah foto galeri ditolak, dengan pesan format.
    case attachment(isFormatRejected: Bool)
    /// Konfirmasi End Session untuk antrean atau sesi yang tampil saat tombol diketuk.
    case leaveAgent(AgentSessionKey)
}
