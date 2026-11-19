//
//  FileManager+ChatAttachment.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import Foundation

extension FileManager {
    /// Salinan file pilihan nasabah di folder sementara aplikasi, karena file dari galeri dihapus sistem setelah
    /// callback-nya selesai. Satu folder unik per salinan, jadi nama file asli tetap dipakai tanpa bentrok. Gagal
    /// menyalin = folder itu dihapus lagi, karena pemanggil tidak menerima URL untuk dibersihkan.
    func copyChatAttachment(from source: URL) throws -> URL {
        let folder = temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try createDirectory(at: folder, withIntermediateDirectories: true)
        let destination = folder.appendingPathComponent(source.lastPathComponent)
        do {
            try copyItem(at: source, to: destination)
        } catch {
            try? removeItem(at: folder)
            throw error
        }
        return destination
    }

    /// Membuang file lampiran yang tidak dipakai lagi, beserta foldernya bila menjadi kosong (folder salinan galeri
    /// atau folder salinan aplikasi Files). Gagal diabaikan: folder sementara tetap dibersihkan sistem.
    func discardChatAttachment(at file: URL) {
        try? removeItem(at: file)
        let folder = file.deletingLastPathComponent()
        guard (try? contentsOfDirectory(atPath: folder.path))?.isEmpty == true else { return }
        try? removeItem(at: folder)
    }
}
