//
//  ReferenceLetterPINRequest.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 16/11/26.
//

import TanyaAI

/// Body verify milik token service host. otpCode bukan otomatis PIN mentah; host memakai pembuat OTP existing.
struct ReferenceLetterPINRequest: Encodable {
    let otpCode: String
    let challengeCode: String?
    let appliNumber: String
    let sequenceNumber: String

    init(otpCode: String, challengeCode: String? = nil, appliNumber: String, sequenceNumber: String) {
        self.otpCode = otpCode
        self.challengeCode = challengeCode
        self.appliNumber = appliNumber
        self.sequenceNumber = sequenceNumber
    }
}

/// Host menentukan responseCodeOTP untuk ACK bersama request tokennya. Tidak diasumsikan sama dengan PIN/otpCode.
struct ReferenceLetterPreparedPIN {
    let request: ReferenceLetterPINRequest
    let verification: ReferenceLetterVerification

    init(request: ReferenceLetterPINRequest, verification: ReferenceLetterVerification) {
        self.request = request
        self.verification = verification
    }
}
