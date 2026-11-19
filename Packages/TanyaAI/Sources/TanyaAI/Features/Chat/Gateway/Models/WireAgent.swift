//
//  WireAgent.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

/// `agent` di event `state` menuju `AGENT_ACTIVE` dan di `data` `agent_joined` (contract §5 dan §7.6): nama agen
/// untuk nasabah. `name` opsional agar objek yang tidak lengkap tidak menggagalkan seluruh event.
struct WireAgent: Decodable {
    let name: String?
}
