//
//  WireSystemNotice.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

/// `data` event SSE `system` (contract §7.6): token jenis notifikasi dan isi per jenis. Isi yang tidak terbaca
/// dianggap kosong, jadi kartunya tetap tampil.
struct WireSystemNotice: Decodable {
    let type: String
    let data: WireSystemNoticeData?

    private enum CodingKeys: String, CodingKey {
        case type
        case data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        data = try? container.decodeIfPresent(WireSystemNoticeData.self, forKey: .data)
    }
}
