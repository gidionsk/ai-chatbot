//
//  UTType+ChatAttachment.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import UniformTypeIdentifiers

extension UTType {
    /// Gambar yang boleh dilampirkan. `.jpeg` mencakup ekstensi `.jpg` dan `.jpeg`.
    static let chatAttachmentImages: [UTType] = [.heic, .jpeg, .png]
    /// Semua format lampiran: PDF dan gambar di atas.
    static let chatAttachments: [UTType] = [.pdf] + chatAttachmentImages

    /// Tipe pertama dari representasi satu foto galeri (urutan sistem, yang asli lebih dulu) yang termasuk gambar
    /// lampiran. Nil = format lain, mis. GIF atau WebP.
    static func chatAttachmentImage(in identifiers: [String]) -> UTType? {
        identifiers.lazy
            .compactMap(UTType.init)
            .first { type in chatAttachmentImages.contains { type.conforms(to: $0) } }
    }
}
