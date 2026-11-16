//
//  ReferenceLetterAuthorization.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

/// Hasil otorisasi sukses dari flow PIN existing host; bukan PIN mentah.
public struct ReferenceLetterAuthorization {
    public let responseCodeOTP: String

    public init(responseCodeOTP: String) {
        self.responseCodeOTP = responseCodeOTP
    }
}

/// Copy hasil ACK yang sudah dipetakan host dari respons BE sukses.
public struct ReferenceLetterReceipt: Equatable {
    public let title: String
    public let message: String

    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}
