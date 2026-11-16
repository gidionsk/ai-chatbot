# Tanya AI — starting point

Package UI iOS 15 untuk migrasi bertahap. DesignKit menyediakan komponen umum;
TanyaAI menyusun welcome, chat, header, dan composer satu sampai empat baris.
Transport HTTP/SSE diimplementasi host; package mengatur sesi chat-gateway dan render pesan Markdown.
Font Fira Sans dan copy English, Bahasa Indonesia, serta 简体中文 tersedia dalam package.

```sh
./Scripts/run_sandbox.sh --language id
./Scripts/run_sandbox.sh --language en
./Scripts/run_sandbox.sh --language zh-Hans
./Scripts/run_sandbox.sh --language id --header-demo
./Scripts/run_sandbox.sh --language id --offline
```

Sandbox menyediakan transport dummy untuk init, history, kirim, dan SSE.
Integrasi layanan host dijelaskan pada [kontrak gateway](docs/CHAT_GATEWAY.md).

Sandbox meniru host SwiftUI: `RootScreen` dengan prelogin dan main coordinator, base
`Screen` per halaman, dan coordinator + destination untuk membuka Tanya AI dari beranda
atau halaman detail.
Tombol kembali atau swipe dari tepi kiri menutup feature dan mengembalikan layar host.
`--offline` menampilkan blocker host di atas Tanya AI saat mengirim.
Mode `--header-demo` menyisipkan teks dummy untuk mengecek separator dan blur
saat scroll. Percakapan kosong menampilkan welcome bila host memberikannya.

- [Aturan penempatan file dan pola intent berikutnya](docs/PACKAGE_STRUCTURE.md)
- [Urutan belajar dan tree](docs/STARTING_POINT.md)
- [Tahap header dan checkpoint migrasi berikutnya](docs/SHARED_HEADER.md)
- [Membuka screen dari host app](docs/HOST_INTEGRATION.md)
- [Pola view dan resource](docs/VIEW_TEMPLATE.md)
- [Aturan implementasi](AGENTS.md)
- [Menjalankan tes (Xcode, workspace host, terminal)](docs/TESTING.md)
- [Hasil validasi](docs/VALIDATION.md)
- [Keputusan revamp dan tahap berikutnya](docs/REVAMP_NOTES.md)

PR starter ditujukan ke branch `startingpoint`; flow lengkap sebelumnya tetap
tersedia di `main`/history. Jalankan `Scripts/verify.sh` sebelum review.
