# Minimal starting point

Ikuti [AGENTS.md](AGENTS.md) untuk aturan token (CustomSizes, CustomTextLines,
CustomColors), nilai awal, theme environment, fonts, localization dan style. Scope aktif:
shared header, composer maksimal empat baris, halaman sambutan (welcome) dari BE, dan
bridge host ke chat-gateway (init → history → SSE, retry, merge); daftar pesan menyusul. Minimum iOS 15 (host ikut naik ke iOS 15 untuk revamp).

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
  Bridge yang menyambung, retry, decode, dan merge (`docs/CHAT_GATEWAY.md`); pesan tampil hanya dari SSE.
  Loading hanya saat history pertama; sambutan hanya bila history kosong. Daftar pesan menyusul.
  `isAwaitingReply` sejak kirim sampai `turn_end` (kartu nonaktif). `ChatTurnPhase`: `LoadingDots` + draft dikunci
  sampai pertanyaan datang dari stream, lalu stop (`cancelTurn` transport, ikon dummy `DesignIcon.stop`) dengan
  draft boleh diketik. Gambar URL lewat `RemoteImage` (cache memori bersama).
- Ukuran welcome/kartu/titik masih estimasi screenshot (TODO di `CustomSizes`/`CustomMotion`);
  aset `chatBackground`/`welcomeOrb` placeholder (`ChatImage`), ganti file, nama tetap.
- Folder TanyaAI: `Bridging/` (API host), `Features/<Fitur>/` (screen di root, tiap bagian
  `Welcome/`, `Composer/` berisi view + modelnya), `Shared/Keys|Extensions`, `Resources/`.
  Tests mencerminkan Sources. Detail di AGENTS.md.
- Unit test memakai Swift Testing (`@Test`, `#expect`, `#require`); UI test tetap
  XCTest. Suite yang memakai window di sandbox masuk `HostWindowTests` (berurutan).
- Sandbox meniru host Byon: coordinator menulis Input UseCase, UseCase mengolah ke Repository, view model
  membaca Repository; Output/callback UseCase induk membuka halaman. `TanyaAIUseCase` = `TanyaAIChatTransport`.
- Keputusan arsitektur dan saran tahap berikutnya: [docs/REVAMP_NOTES.md](docs/REVAMP_NOTES.md).

Panduan implementasi dan urutan belajar: [docs/STARTING_POINT.md](docs/STARTING_POINT.md).
