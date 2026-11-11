# Minimal starting point

Ikuti [AGENTS.md](AGENTS.md) untuk aturan token (CustomSizes, CustomTextLines,
CustomColors), nilai awal, theme environment, fonts, localization dan style. Scope aktif:
shared header, composer maksimal empat baris, halaman sambutan (welcome) dari BE, dan
bridge host ke chat-gateway (init → history → SSE, retry, merge), dan daftar pesan `ChatTable` (`UITableView`, baris SwiftUI; aturannya di `docs/REVAMP_NOTES.md`). Minimum iOS 15 (host ikut naik ke iOS 15 untuk revamp).

- Tanpa `if ... else`, pakai early return; atribut variabel satu baris dengan variabelnya. Detail di AGENTS.md.
- Semua teks memakai Fira Sans. Open Sans belum dipakai: jangan jadi default komponen atau dipakai di layar.
- Ukuran dan area tap 1:1 Figma lewat `.scaledToArtwork`. Jangan menambahkan
  minimum touch target 44 atau hit frame tambahan; ini keputusan UI/UX.
- Header = ukuran navigation bar host: dari tepi layar, padding atas 50/28 tanpa scale
  (`CustomScreenInsets`), kiri-kanan 20, bawah 15, ikon 24, judul Fira Sans Bold 16.
  Saat digulir putih + `designShadow` (Figma Shadow/Default) + gradient fade di belakangnya.
- Tanpa R.swift/build tool plugin (CI host tidak bisa trust plugin). Copy lewat `ChatCopy`/`SandboxCopy`,
  ikon lewat `DesignIcon`; tambah case setiap menambah key/imageset, tes menjaga kecocokannya.
- Welcome: host men-decode inquiry init dengan model miliknya, memetakan ke `WelcomeContent`
  (struct biasa, tanpa `Decodable`) dan mengisi `TanyaAIHost(welcome:)`. Decode di TanyaAI hanya
  untuk hasil stream nanti. Sapaan, judul/deskripsi/ikon kartu dari BE; emblem, latar, judul
  daftar dan chevron dari FE. Ketuk kartu = kirim `prompt` lewat bridge.
- `TanyaAIBridge` dipegang host (dibuat sekali) dengan `TanyaAIChatTransport` per endpoint (body mentah).
  Bridge yang menyambung, retry, decode, dan merge (`docs/CHAT_GATEWAY.md`). Bubble pertanyaan tampil saat
  kirim (`LocalQuestion`), diganti salinan SSE lewat `client_msg_id`/seq ack; gagal kirim = bubble abu-abu +
  hint tanpa retry. Loading hanya saat history pertama; sambutan hanya bila history kosong. Chip tanggal
  (`DateChip`, `d MMM yyyy`, zona perangkat) di atas pertanyaan pertama tiap hari; bubble lokal memakai waktu kirim.
  Saran lanjutan = `SuggestionChip` di bawah jawaban terakhir, diketuk = terkirim seperti shortcut.
  Live agent: kartu status (frame 62/64) dari event `system`, kartu antre + tombol batal hanya selama antre, pesan
  agen dengan avatar dan label statis (frame 68), "Agen sedang mengetik..." miring. History tanpa event `system`:
  kartu selesai diturunkan dari pesan agen; kartu batal/tidak tersedia hanya selama halaman terbuka.
  Jawaban bot = `MarkdownContent` (parser Apple: CommonMark + GFM, tanpa HTML; gambar lewat `RemoteImage`), link ke host lewat
  `makeView(onOpenLink:)`.
  `isAwaitingReply` sejak kirim sampai `turn_end` (kartu nonaktif). Tanpa titik bergerak: tombol langsung stop
  (`cancelTurn` transport, ditahan sampai ack) dengan draft boleh diketik. Tombol memakai ikon berwarna
  `DesignColorIcon` `send-on`/`send-off`/`send-pause` (dummy, nama aset Byon); stopping = redup `.plain` bawaan.
  Gambar URL lewat `RemoteImage` (cache memori bersama).
- Ukuran welcome/kartu/bubble masih estimasi screenshot (TODO di `CustomSizes`);
  aset `chatBackground`/`welcomeOrb` placeholder (`ChatImage`), ganti file, nama tetap.
- Struktur fungsi → jenis file: [docs/PACKAGE_STRUCTURE.md](docs/PACKAGE_STRUCTURE.md).
  TanyaAI: `Bridging/` untuk konfigurasi/kontrak host; `Features/Chat/` berisi screen dan bagian-bagiannya.
  `Messages` mengurus nilai/bubble, `ConversationList` daftar/scroll, `Session` bridge/state,
  `Gateway` decode/protokol, `Keys` accessor fitur. Welcome tetap bagian Chat.
  DesignKit: `Components/<Fungsi>`, `Foundations`, `Extensions`, `Tokens`, `Resources`.
  Kelompok beberapa file memakai Models/Views/Controllers/Extensions sesuai peran di dalam pemiliknya.
  Tests mencerminkan Sources. Intent di `Chat/Intents/<Nama>`; `LiveAgent` digerakkan event gateway.
  Pola intent berbentuk flow host (form/PIN) dikonfirmasi saat flow pertama dimulai.
- Unit test memakai Swift Testing (`@Test`, `#expect`, `#require`); UI test tetap
  XCTest. Suite yang memakai window di sandbox masuk `HostWindowTests` (berurutan).
- Sandbox meniru host Byon: coordinator menulis Input UseCase, UseCase mengolah ke Repository, view model
  membaca Repository; Output/callback UseCase induk membuka halaman. `TanyaAIUseCase` = `TanyaAIChatTransport`.
- Keputusan arsitektur dan saran tahap berikutnya: [docs/REVAMP_NOTES.md](docs/REVAMP_NOTES.md).

Panduan implementasi dan urutan belajar: [docs/STARTING_POINT.md](docs/STARTING_POINT.md).
