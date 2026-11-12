//
//  ChatScrollMode.swift
//  TanyaAI
//
//  Created by Wendra on 11/11/26.
//

/// Siapa yang sedang menentukan posisi daftar pesan. Satu nilai, jadi kombinasi yang tidak sah (mis. parkir dijaga
/// sambil mengikuti ke bawah) tidak bisa ditulis.
enum ChatScrollMode {
    /// Posisi milik nasabah; hanya acuan posisi baca yang menjaganya.
    case free
    /// Pertanyaan baru parkir dekat atas dan posisinya dijaga walau layout berubah, sampai nasabah menggeser.
    case holdingQuestion
    /// Nasabah sudah menggeser: posisi miliknya, tetapi ruang kosong di bawah masih mengikuti tinggi jawaban.
    case releasedQuestion
    /// Animasi menuju pesan terbaru belum sampai ke ujung yang sudah terukur.
    case followingLatest

    /// Ruang kosong di bawah konten masih disediakan untuk pertanyaan yang parkir.
    var isQuestionParked: Bool { self == .holdingQuestion || self == .releasedQuestion }

    /// Mode setelah nasabah mulai menggeser: parkir tidak lagi dijaga dan animasi ke pesan terbaru batal.
    var afterDrag: ChatScrollMode {
        switch self {
        case .holdingQuestion, .releasedQuestion: return .releasedQuestion
        case .free, .followingLatest: return .free
        }
    }
}
