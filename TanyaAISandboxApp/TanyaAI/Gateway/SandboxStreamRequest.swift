//
//  SandboxStreamRequest.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 30/10/26.
//

/// Pengganti `DataStreamRequest` Alamofire di sandbox: hanya kemampuan menutup stream.
struct SandboxStreamRequest {
    let cancel: () -> Void
}
