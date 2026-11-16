//
//  SandboxFixtureFile.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 27/10/26.
//

import Foundation

/// File JSON dummy BE di `Resources/Fixtures`. Nama case = nama file tanpa `.json`.
enum SandboxFixtureFile: String, CaseIterable {
    case tanyaAIInitDummy = "TanyaAIInitDummy"
    case referenceLetterInquiry = "ReferenceLetterInquiry"
    /// Halaman history chat-gateway: empat pesan di dua tanggal, terbaru dulu.
    case tanyaAIHistoryDummy = "TanyaAIHistoryDummy"

    /// Lokasi file di bundle app; nil bila file tidak ikut ter-bundle.
    var url: URL? {
        Bundle.main.url(forResource: rawValue, withExtension: "json")
    }
}
