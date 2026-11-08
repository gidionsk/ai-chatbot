//
//  WireError.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

/// Error envelope gateway: `{success:false, error_code, message, data, retryable, request_id}`.
/// Hanya field yang menentukan retry yang dibaca; `message` tidak ditampilkan ke pengguna.
struct WireError: Decodable {
    let isRetryable: Bool
    let data: WireRetryHint?

    private enum CodingKeys: String, CodingKey {
        case isRetryable = "retryable"
        case data
    }
}
