//
//  WireSystemNoticeData.swift
//  TanyaAI
//
//  Created by Wendra on 20/11/26.
//

/// `data` event `system` (contract §7.6). Hanya `agent` dari `agent_joined` yang dipakai; `topic` dari
/// `agent_connecting` belum dipakai, dan jenis lain mengirim null.
struct WireSystemNoticeData: Decodable {
    let agent: WireAgent?
}
