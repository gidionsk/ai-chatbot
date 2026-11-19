//
//  UTTypeChatAttachmentTests.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import Testing
import UniformTypeIdentifiers

@testable import TanyaAI

/// Lampiran hanya PDF, HEIC, JPG/JPEG, dan PNG.
struct UTTypeChatAttachmentTests {
    @Test(arguments: ["pdf", "heic", "jpg", "jpeg", "png", "PNG"])
    func supportedExtensionsAreAllowedInFiles(fileExtension: String) throws {
        let type = try #require(UTType(filenameExtension: fileExtension))
        #expect(UTType.chatAttachments.contains { type.conforms(to: $0) })
    }

    @Test(arguments: ["gif", "webp", "heif", "tiff", "docx", "mov"])
    func otherFormatsAreRejectedInFiles(fileExtension: String) throws {
        let type = try #require(UTType(filenameExtension: fileExtension))
        #expect(!UTType.chatAttachments.contains { type.conforms(to: $0) })
    }

    /// Representasi asli foto (urutan pertama) dipakai bila didukung; foto berformat lain ditolak.
    @Test(arguments: [
        (["public.heic", "public.jpeg"], UTType.heic as UTType?),
        (["public.jpeg"], .jpeg),
        (["com.apple.live-photo-bundle", "public.png"], .png),
        (["com.compuserve.gif"], nil),
        (["org.webmproject.webp"], nil),
        ([], nil)
    ])
    func galleryPhotoUsesItsFirstSupportedRepresentation(identifiers: [String], expected: UTType?) {
        #expect(UTType.chatAttachmentImage(in: identifiers) == expected)
    }
}
