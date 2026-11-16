//
//  ReferenceLetterEndpoint.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 16/11/26.
//

/// Route BE milik project host; tidak diekspor melalui SDK TanyaAI.
enum ReferenceLetterEndpoint: String {
    case inquiry = "/user/tanya-ai/reference-letter/inquiry"

    var method: String { "GET" }
}

enum ReferenceLetterResponseCode: String {
    case success = "00000"
}
