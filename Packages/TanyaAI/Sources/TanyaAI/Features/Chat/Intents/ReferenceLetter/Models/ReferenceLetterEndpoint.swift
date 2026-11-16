//
//  ReferenceLetterEndpoint.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Kontrak route BE. Base URL, header, autentikasi, dan implementasi HTTP tetap milik host.
public enum ReferenceLetterEndpoint: String {
    case inquiry = "/user/tanya-ai/reference-letter/inquiry"
    case verifyPIN = "/token/v4/verify/pin/otp"
    case acknowledge = "/user/tanya-ai/reference-letter/ack"

    public var method: String { self == .inquiry ? "GET" : "POST" }
}

enum ReferenceLetterResponseCode: String {
    case success = "00000"
    case invalidPIN = "05516"
    case blockedPIN = "05005"
}
