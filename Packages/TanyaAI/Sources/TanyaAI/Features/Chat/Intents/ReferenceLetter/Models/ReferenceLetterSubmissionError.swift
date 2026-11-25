//
//  ReferenceLetterSubmissionError.swift
//  TanyaAI
//
//  Created by Wendra on 22/11/26.
//

/// Host memetakan status verifikasi dan balikan ACK ke hasil yang berbeda.
public enum ReferenceLetterSubmissionError: Error {
    /// Pesan aman dari host untuk kegagalan verifikasi PIN. Nil memakai pesan bawaan sheet PIN.
    case pinVerification(message: String?)
    /// Error ACK asli diteruskan kembali ke host setelah sheet PIN ditutup.
    case acknowledgement(Error)
}
