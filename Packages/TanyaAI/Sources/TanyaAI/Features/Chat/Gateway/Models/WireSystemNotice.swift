//
//  WireSystemNotice.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

/// `data` event SSE `system` (contract §7.6): token jenis notifikasi. `data` per jenis belum dipakai.
struct WireSystemNotice: Decodable {
    let type: String
}
