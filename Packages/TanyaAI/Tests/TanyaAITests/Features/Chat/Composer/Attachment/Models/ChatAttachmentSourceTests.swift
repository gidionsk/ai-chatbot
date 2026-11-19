//
//  ChatAttachmentSourceTests.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import Testing

@testable import TanyaAI

/// Baris bottom sheet lampiran: Galeri lalu File, id unik, dan setiap baris punya judul serta keterangan format.
struct ChatAttachmentSourceTests {
    @Test
    func sheetRowsAreGalleryThenFileWithUniqueIDs() {
        #expect(ChatAttachmentSource.allCases == [.gallery, .file])
        let ids = ChatAttachmentSource.allCases.map(\.optionID)
        #expect(Set(ids).count == ids.count)
        #expect(ids.allSatisfy { !$0.isEmpty })
    }

    @Test(arguments: [
        (ChatAttachmentSource.gallery, ChatCopy.attachmentGallery, ChatCopy.attachmentGalleryFormats),
        (.file, .attachmentFile, .attachmentFileFormats)
    ])
    func eachRowHasItsTitleAndFormats(source: ChatAttachmentSource, title: ChatCopy, formats: ChatCopy) {
        #expect(source.title == title)
        #expect(source.formats == formats)
    }
}
