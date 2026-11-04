//
//  TanyaAIInitResponse.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 27/10/26.
//

/// Tiruan model response inquiry init di host. Envelope (`response_code`, dll.) milik network layer host.
struct TanyaAIInitResponse: Decodable {
    let data: TanyaAIInitData
}
