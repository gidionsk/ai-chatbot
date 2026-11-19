//
//  ChatAttachmentSource.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

/// Asal lampiran yang dipilih nasabah di bottom sheet tombol `+`. Kamera sengaja tidak ada (keputusan user).
enum ChatAttachmentSource: CaseIterable, Identifiable {
    /// Galeri foto sistem: satu gambar HEIC, JPG/JPEG, atau PNG.
    case gallery
    /// Aplikasi Files: PDF atau gambar dengan format yang sama.
    case file

    var id: Self { self }

    /// Id baris di `OptionList`; nama case, jadi stabil tanpa teks tambahan.
    var optionID: String { String(describing: self) }

    var title: ChatCopy {
        switch self {
        case .gallery: return .attachmentGallery
        case .file: return .attachmentFile
        }
    }

    /// Format yang diterima, sebagai keterangan di bawah judul baris.
    var formats: ChatCopy {
        switch self {
        case .gallery: return .attachmentGalleryFormats
        case .file: return .attachmentFileFormats
        }
    }
}
