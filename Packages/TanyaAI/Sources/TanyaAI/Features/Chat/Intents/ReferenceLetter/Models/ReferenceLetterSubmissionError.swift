//
//  ReferenceLetterSubmissionError.swift
//  TanyaAI
//
//  Created by Wendra on 22/11/26.
//

/// Host memetakan status verifikasi dan balikan ACK ke hasil yang berbeda.
public enum ReferenceLetterSubmissionError: Error {
    /// Pesan aman untuk pengguna. `isBlocked` mengikuti status blokir yang dikembalikan backend host.
    case pinVerification(message: String?, isBlocked: Bool)
    /// Error ACK asli diteruskan kembali ke host setelah sheet PIN ditutup.
    case acknowledgement(Error)
}
