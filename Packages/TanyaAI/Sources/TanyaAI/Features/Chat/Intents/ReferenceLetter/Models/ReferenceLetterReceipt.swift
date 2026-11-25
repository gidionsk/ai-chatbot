//
//  ReferenceLetterReceipt.swift
//  TanyaAI
//
//  Created by Wendra on 22/11/26.
//

/// Kartu hasil ACK dan ID bukti transaksi bila disediakan host.
public struct ReferenceLetterReceipt {
    public let title: String
    public let message: String
    public let successID: String?

    public init(title: String, message: String, successID: String? = nil) {
        self.title = title
        self.message = message
        self.successID = successID
    }
}
