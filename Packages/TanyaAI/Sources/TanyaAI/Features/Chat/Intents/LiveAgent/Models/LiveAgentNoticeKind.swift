//
//  LiveAgentNoticeKind.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

/// Jenis event `system` (contract §7.6) yang menjadi chip atau kartu status live agent. Nilai mentah = token
/// gateway; copy milik aplikasi. `back_to_assistant` tidak dipakai karena selalu datang bersama event penutup.
enum LiveAgentNoticeKind: String, Equatable {
    /// Agen bergabung (`AGENT_ACTIVE`): chip "sesi dimulai", tanpa kartu.
    case joined = "agent_joined"
    /// Masuk antrean agen (`AGENT_QUEUED`).
    case connecting = "agent_connecting"
    /// Agen menutup percakapan.
    case ended = "agent_ended"
    /// Agen tidak membalas sampai batas waktu (default 10 menit).
    case idleTimeout = "agent_idle_timeout"
    /// Nasabah keluar dari antrean lewat `leave-agent`.
    case canceled = "queue_canceled"
    /// Waktu antre habis tanpa agen yang bergabung.
    case queueTimeout = "queue_timeout"
    /// Sambungan ke sistem agen ditolak atau hilang.
    case unavailable = "agent_unavailable"
    /// Bukan event gateway (tidak ada di katalog §7.6): dibuat dari pesan bot ber-intent `liveAgent` di history
    /// yang tidak diikuti pesan agen. Penyebabnya (batal, antre habis, agen tidak tersedia) tidak diketahui.
    case notContinued = "handover_not_continued"
}
