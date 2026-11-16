# Surat Referensi — inquiry, form, dan PIN existing

Perubahan dipisah dalam dua scope dan enam PR berurutan. Tiap PR memakai hasil PR sebelumnya; integrasikan lewat
review Wendra, lalu sesuaikan base PR berikutnya ke startingpoint terbaru. Jangan merge otomatis.

| Scope | PR / branch | Batas perubahan |
| --- | --- | --- |
| 1: inquiry/form | `feature/reference-letter-inquiry` | Model inquiry/draft, mapping dan adapter inquiry host, subtitle pilihan rekening |
| 1: inquiry/form | `feature/reference-letter-form-ui` | Susunan form serta daftar pilihan dari komponen existing; validasi caller |
| 1: inquiry/form | `feature/reference-letter-inquiry-chat` | Inquiry per message_id, sheet pilihan di root chat, history read-only |
| 1: inquiry/form | `feature/reference-letter-inquiry-demo` | Fixture dan demo inquiry di aplikasi host; Kirim masih nonaktif |
| 2: PIN/ACK | `feature/reference-letter-host-ack` | Kontrak otorisasi flow PIN existing dan mapping ACK host; tidak menambah verifikasi PIN |
| 2: PIN/ACK | `feature/reference-letter-pin-ack` | Validasi Kirim, otorisasi host → ACK, kartu hasil/catatan, demo dan tes flow |

Setelah scope 1, host dapat menampilkan dan mengisi form menggunakan response inquiry. Tombol Kirim belum aktif
sampai `referenceLetterSubmission` dipasang pada scope 2. Ini mencegah tombol memberi kesan transaksi berhasil
ketika belum ada integrasi submit.

## Perilaku

Intent `request-bank-reference-letter` membuat satu instance form per message_id di bridge, di luar sel table.
Replay mempertahankan instance dan inquiry hanya dijalankan sekali. History tidak memanggil service transaksi.
Pilihan berasal dari inquiry BE, bukan label/kode buatan; purpose dan document format default indeks 0. Rekening
bisa lebih dari satu. Email/alamat tidak bisa diedit; format SOFTCOPY/HARDCOPY menentukan field yang ditampilkan.
Form memakai SelectField, TextInputField, ToggleRow, FilledButton, OptionList dan bottomSheet existing.

Pada scope 2, Kirim menampilkan error field wajib dengan komponen existing. Sesudah valid, SDK membuat snapshot
pilihan dan meminta otorisasi host. Host membuka PIN existing dan memverifikasi dengan flow BE yang sudah ada.
SDK tidak membuat sheet PIN, tidak menerima enam angka PIN, dan tidak mendefinisikan endpoint verifikasi PIN.
Batal dari flow host kembali ke form tanpa ACK. Hanya otorisasi sukses yang meneruskan snapshot ke service ACK.
Submit ganda selama otorisasi/ACK diabaikan; perubahan draft tidak mengubah snapshot transaksi berjalan.

Sukses ACK mengganti form menjadi kartu pemesanan. Title hasil BE dipakai jika terisi; data.message tampil persis
di bawah kartu. Penolakan eksplisit ACK kembali ke form dengan error. Timeout/malformed ACK menjadi status belum
pasti dan tidak di-retry otomatis. Hasil otorisasi lama setelah halaman/percakapan ditutup tidak memulai ACK.
Presentasi dan lifecycle PIN tetap ditangani project host dengan mekanisme existing.

Detail protocol dan contoh pemasangan host: [REFERENCE_LETTER_SERVICE.md](REFERENCE_LETTER_SERVICE.md).

## Demo

```sh
./Scripts/run_sandbox.sh --language id --reference-letter-demo
./Scripts/run_sandbox.sh --language en --reference-letter-demo --reference-letter-authorization-cancelled
./Scripts/run_sandbox.sh --language id --reference-letter-demo --reference-letter-authorization-error
./Scripts/run_sandbox.sh --language id --reference-letter-demo --reference-letter-ack-timeout
```

Buka TanyaAI dan kirim satu pertanyaan untuk menerima intent fixture. Demo scope 1 hanya memasang inquiry.
Demo scope 2 juga memasang callback fixture hasil otorisasi host dan response ACK fixture. Callback fixture ini
langsung mengembalikan hasil sukses/batal/gagal; tidak menggantikan PIN existing project utama dan tidak menguji
verifikasi BE nyata. Tidak ada koneksi ke bank, generator OTP, atau logging PIN/body. Lookup email fixture juga
bukan algoritma dekripsi produksi.

Sebanyak 16 tes model/adapter dalam empat suite lulus di harness pure Swift Linux yang memakai source asli
dengan module SDK dan host terpisah. Tes lifecycle SDK tersedia untuk Xcode; belum dijalankan. Guard design
system, formatting, dan syntax juga diperiksa di Linux. Build Xcode, SwiftLint,
unit/UI test iOS lengkap, VoiceOver, layout iOS 15, dan integrasi coordinator PIN nyata memerlukan macOS serta
project host; belum dijalankan di lingkungan ini.
