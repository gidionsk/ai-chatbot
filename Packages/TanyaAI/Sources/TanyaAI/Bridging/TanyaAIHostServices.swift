//
//  TanyaAIHostServices.swift
//  TanyaAI
//
//  Created by Wendra on 23/11/26.
//

/// Service intent yang disediakan host lewat parameter `hostServices:` pada bridge.
@MainActor
public protocol TanyaAIHostServices: AnyObject {
    /// Nil jika Surat Referensi tidak tersedia. Inquiry dimulai melalui service setelah form disiapkan.
    var referenceLetter: ReferenceLetterService? { get }
}
