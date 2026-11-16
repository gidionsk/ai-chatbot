# Surat Referensi — form, PIN, dan ACK

Intent gateway `request-bank-reference-letter` membuat satu instance form per `message_id`, disimpan bridge di luar
sel table. Replay memakai instance yang sama. Host tanpa service intent tetap memakai API lama dan tidak menampilkan
form. History hanya menampilkan kartu pernah-request dan tidak memanggil inquiry, verify, atau ACK.

## Alur

1. Inquiry GET `/user/tanya-ai/reference-letter/inquiry` melalui service host.
2. Host menyediakan HTTP authenticated, generator OTP, dan fungsi dekripsi email existing ke adapter.
3. Form memakai `SelectField`, `TextInputField`, `ToggleRow`, `FilledButton`, dan `OptionList` existing.
4. Kirim menandai field kosong/tidak tersedia. Pilihan kosong paling atas dibuka di sheet; tidak mengirim request.
5. Bila valid, snapshot request dibuat sebelum sheet PIN dibuka. Perubahan draft berikutnya tidak mengubah snapshot.
6. Enam digit ASCII diteruskan sekali ke generator token host. Input keypad dibersihkan sebelum callback.
7. POST `/token/v4/verify/pin/otp`; hanya `response_code == "00000"` membuka langkah ACK.
8. POST `/user/tanya-ai/reference-letter/ack`; hanya kode sukses dengan data hasil yang mengganti form menjadi kartu.
   `data.title` dipakai bila tidak kosong, dan `data.message` ditampilkan persis di bawah kartu.

PIN salah (05516) tetap di sheet dengan pesan BE dan bisa diisi kembali. PIN terblokir (05005) mengunci flow.
05000/05006 dan kode verifikasi lain tidak mengirim ACK. Submit ganda diabaikan. Sheet tidak dapat ditutup dan
swipe-back host ditahan selama verifikasi/ACK. Bila ACK timeout atau responsnya tidak terbaca, status menjadi
belum pasti dan tidak di-retry otomatis: request mungkin sudah diterima BE. Penolakan ACK eksplisit mengembalikan
form agar nasabah dapat memperbaikinya. Tidak ada kode pemesanan/idempotency baru yang dikarang package.

## Mapping inquiry dan ACK

| Sumber inquiry | Tampilan / request |
| --- | --- |
| `purposes` | Pilihan satu; default elemen pertama |
| `documentFormats` | Pilihan satu; default elemen pertama; perilaku memakai kode SOFTCOPY/HARDCOPY |
| `sourceAccounts` | Checkmark pilihan banyak; `description` menjadi subtitle tanpa parsing nominal |
| `currencies` | Pilihan satu; kode BE disimpan, label tidak dipakai sebagai kode |
| `languages` | Pilihan bahasa, karena ACK membutuhkan objek `language`; tanpa default tambahan |
| `address` | Read-only, tampil untuk HARDCOPY |
| `email` | Ciphertext asli disimpan untuk ACK; hanya hasil decrypt host tampil untuk SOFTCOPY |
| `onlineSessionId` | Dipertahankan pada snapshot ACK |

Tujuan, rekening, mata uang, bahasa, format, dan kedutaan/instansi divalidasi ketika Kirim. Email/alamat bukan input
draft dan tidak ikut validasi field wajib. Mengganti format hanya mengganti field delivery; tidak menciptakan atau
mengubah alamat/email dari BE. Toggle awal mengikuti foto: saldo aktif, investasi nonaktif. Daftar kosong tidak
menjadi nilai pilihan yang dikarang. ID kosong/ganda dinormalisasi sekali saat inquiry dipetakan; urutan pertama BE
dipertahankan. Field pilihan menyimpan kode, dan ACK mengirim objek code/value/description dari inquiry.

## Adapter host

```swift
let referenceLetter = ReferenceLetterServiceAdapter(
    locale: locale,
    fallbackMessage: localizedServiceError,
    send: { endpoint, body in
        // Gunakan base URL, header, autentikasi, dan error handler service Byon existing.
        try await userService.request(path: endpoint.rawValue, method: endpoint.method, body: body)
    },
    preparePIN: { pin in
        // Pakai token service existing. Jangan langsung menganggap pin == otpCode == responseCodeOTP.
        let token = try await tokenService.prepare(pin: pin)
        return ReferenceLetterPreparedPIN(
            request: ReferenceLetterPINRequest(
                otpCode: token.otpCode,
                challengeCode: token.challengeCode,
                appliNumber: token.appliNumber,
                sequenceNumber: token.sequenceNumber
            ),
            verification: ReferenceLetterVerification(responseCodeOTP: token.responseCodeOTP)
        )
    },
    decryptEmail: { try existingCrypto.decrypt($0) }
)
let bridge = TanyaAIBridge(
    transport: chatTransport,
    services: TanyaAIIntentServices(referenceLetter: referenceLetter)
)
let host = TanyaAIHost(locale: locale, bridge: bridge)
host.makeView(onSheetPresented: { isPresented in
    // Tahan swipe-back pada navigation controller host selama sheet terbuka.
    navigationController.setPopGestureEnabled(!isPresented)
})
```

Nama `userService`, `tokenService`, `existingCrypto`, dan properti token di contoh adalah titik pemetaan, bukan API
Byon yang tersedia di repo ini. Signature/generator asli, konfigurasi jaringan, header dan credential tidak diberikan
dalam handoff. Package menyediakan protocol bertipe dan adapter contract, tanpa menebak implementasi kriptografi.
Host juga dapat mengimplementasikan `ReferenceLetterService` langsung bila model/service Byon sudah tersedia.

`TransactionPINEntry` adalah isi keypad reusable baru di DesignKit; komponen PIN belum ada pada baseline. Ia tidak
memegang service. `OptionItem.subtitle` diperluas dengan default nil agar daftar rekening memakai komponen pilihan
existing. Ukuran keypad memakai token existing; simbol native lock/doc adalah placeholder sampai aset dan dimensi
Figma final tersedia. Flow memakai lifecycle bersama `FormSubmissionPhase` dan presenter sheet di folder Form;
tidak menambah DSL field, mesin jaringan, atau coordinator navigasi baru untuk satu form.

## Demo dan verifikasi

```sh
./Scripts/run_sandbox.sh --language id --reference-letter-demo
./Scripts/run_sandbox.sh --language en --reference-letter-demo --reference-letter-pin-error
./Scripts/run_sandbox.sh --language id --reference-letter-demo --reference-letter-ack-timeout
```

Buka TanyaAI dan kirim satu pertanyaan. Gateway fixture memberi intent Surat Referensi. Demo menjalankan adapter dan
decoder yang sama dengan production memakai JSON fixture. Enam angka apa pun diterima mock token; flag pin-error
mengembalikan 05516 pada percobaan pertama, lalu sukses. Stub OTP dan lookup email fixture bukan kriptografi produksi.
Tidak ada request ke bank atau pencatatan PIN/body request. `ReferenceLetterInquiry.json` berisi data contoh dan marker
email fixture; `ReferenceLetterACK.json` berisi catatan hasil seperti foto kontrak BE.

Tests ditambahkan untuk default BE, data kosong, kode tak dikenal, urutan pilihan, ciphertext ACK, routing error
verifikasi, request snapshot, pemanggilan verify sebelum ACK, PIN terblokir, submit ganda, timeout ACK, replay,
history read-only, dan respons lama setelah pergantian percakapan. UI test mencakup delivery read-only, validasi,
PIN salah lalu sukses, serta pesan ACK. Jalankan `Scripts/verify.sh` di macOS/Xcode sebelum integrasi.

Pemeriksaan lokal di Linux mencakup guard design system, konsistensi localization, Swift-format 6.2.1 dengan config
repo, syntax parser, dan diff/ukuran file. Model serta adapter pure Swift: 13 test dalam 3 suite lulus melalui
harness terisolasi yang memakai source/test asli; manifest repository tidak diubah. Ini bukan build iOS.
SwiftLint, formatter Xcode, unit test package lengkap, UI test, VoiceOver dan layout iOS 15 belum dijalankan.
