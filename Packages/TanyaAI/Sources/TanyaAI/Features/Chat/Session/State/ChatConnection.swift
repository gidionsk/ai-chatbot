//
//  ChatConnection.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

/// Status sambungan ke gateway selama halaman terbuka.
enum ChatConnection: Equatable {
    /// Init, mengejar history, atau menunggu jeda sebelum menyambung ulang.
    case connecting
    /// Stream SSE terbuka.
    case live
    /// Percakapan `CLOSED`/diarsipkan, atau error yang tidak bisa di-retry; tidak menyambung ulang.
    case closed
    /// Sesi OMNI habis (401); host yang mengarahkan login ulang.
    case expired
}
