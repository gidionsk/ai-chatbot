//
//  ReferenceLetterPINRequest.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

/// Body verify milik token service host. otpCode bukan otomatis PIN mentah; host memakai pembuat OTP existing.
public struct ReferenceLetterPINRequest: Encodable {
    public let otpCode: String
    public let challengeCode: String?
    public let appliNumber: String
    public let sequenceNumber: String

    public init(otpCode: String, challengeCode: String? = nil, appliNumber: String, sequenceNumber: String) {
        self.otpCode = otpCode
        self.challengeCode = challengeCode
        self.appliNumber = appliNumber
        self.sequenceNumber = sequenceNumber
    }
}

/// Host menentukan responseCodeOTP untuk ACK bersama request tokennya. Tidak diasumsikan sama dengan PIN/otpCode.
public struct ReferenceLetterPreparedPIN {
    public let request: ReferenceLetterPINRequest
    public let verification: ReferenceLetterVerification

    public init(request: ReferenceLetterPINRequest, verification: ReferenceLetterVerification) {
        self.request = request
        self.verification = verification
    }
}
