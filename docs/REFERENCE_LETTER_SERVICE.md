# Surat Referensi — service project host

Route endpoint form dan mapping model BE berada di project host. SDK TanyaAI hanya menerima nilai bertipe lewat
protocol, mengikuti ownership jaringan live agent. `TanyaAIChatTransport` tetap khusus chat-gateway.

## Scope 1: inquiry ke form

`ReferenceLetterService.inquiry()` mengembalikan `ReferenceLetterInquiry`. Host memanggil GET
`/user/tanya-ai/reference-letter/inquiry` lewat service existing, memeriksa status BE, melakukan dekripsi email
existing, lalu memetakan code/value/description ke `OptionItem` existing. `ReferenceLetterServiceAdapter` pada
`TanyaAISandboxApp/ReferenceLetter` adalah contoh mapping host. Bila project utama sudah punya model/service,
gunakan model tersebut langsung; tidak perlu menggandakan adapter sandbox.

Default purposes dan documentFormats memakai elemen pertama. Source accounts memakai pilihan banyak/checkmark,
dengan description sebagai subtitle. Daftar kosong dan kode tak dikenal tidak menghasilkan pilihan buatan.
Alamat dan email read-only: SOFTCOPY menampilkan email hasil decrypt host, HARDCOPY menampilkan alamat inquiry.
Ciphertext email tetap tersedia untuk snapshot submit. Label, mata uang, dan nominal tetap mengikuti data inquiry.

Host inquiry saja dapat memasang `TanyaAIIntentServices(referenceLetter: inquiryService)`. Form dan daftar pilihan
bisa dipakai; Kirim nonaktif sampai capability submit dipasang pada scope 2. `ReferenceLetterForm` juga dapat
digunakan langsung dengan binding draft, validasi caller, dan callback onSubmit opsional.

## Scope 2: PIN existing dan ACK

Scope ini menambahkan `ReferenceLetterSubmissionService`, terpisah dari service inquiry:

- `authorize()` meminta project host menjalankan flow PIN existing beserta verifikasi BE existing.
- Hasil sukses dipetakan menjadi `ReferenceLetterAuthorization(responseCodeOTP:)`; batal mengembalikan nil.
- `acknowledge(_:authorization:)` memetakan snapshot dan hasil otorisasi ke POST
  `/user/tanya-ai/reference-letter/ack`, lalu mengembalikan title/message dari ACK sukses.

Tidak ada route PIN, DTO verify, generator OTP, keypad, atau pemanggilan verifikasi PIN tambahan pada perubahan
ini. Angka PIN tidak masuk ke SDK. Retry PIN salah, blocked PIN, presentasi dan penutupan sheet, serta pembatalan
ketika halaman host ditutup tetap ditangani flow existing project. SDK mengabaikan hasil otorisasi lama bila
instance form/percakapan sudah dibatalkan, sehingga hasil lama tidak memulai ACK.

Contoh pemasangan **di project host**; nama coordinator/service di bawah adalah titik pemetaan, bukan nama API
project utama yang tersedia di repo sandbox:

```swift
let submitService = ReferenceLetterSubmissionAdapter(
    fallbackMessage: localizedServiceError,
    authorizeWithHost: {
        // Panggil flow PIN existing satu kali dan tunggu hasil verifikasi yang sudah ditanganinya.
        guard let result = try await existingPINFlow.authorize() else { return nil }
        return ReferenceLetterAuthorization(responseCodeOTP: result.responseCodeOTP)
    },
    send: { endpoint, body in
        try await existingUserService.request(path: endpoint.rawValue, method: endpoint.method, body: body)
    }
)
let services = TanyaAIIntentServices(
    referenceLetter: inquiryService,
    referenceLetterSubmission: submitService
)
```

Jika flow existing memakai callback, project host membungkus callback sukses/batal/gagal ke async dengan
continuation yang diselesaikan tepat sekali. Jangan menjalankan endpoint verify lagi setelah flow existing sukses.
SDK tidak mengetahui detail route, sequence/challenge, atau cara token diperoleh.

ACK hanya dikirim setelah otorisasi sukses dengan hasil yang terisi. Snapshot mempertahankan kode, label,
description rekening, alamat, ciphertext email, bahasa dan onlineSessionId dari inquiry. DTO ACK serta encoding
JSON adalah milik host. Respons business error walau HTTP 200 dilempar sebagai penolakan; respons sukses tanpa
receipt atau kegagalan transport tidak boleh dianggap berhasil. Tidak ada retry ACK otomatis.

## Verifikasi

Unit tests SDK mencakup data/default, pilihan banyak, field wajib, snapshot, dan lifecycle per instance. Tests host
mencakup mapping inquiry, dekripsi yang diinjeksi, callback otorisasi tanpa request PIN tambahan, payload ACK,
batal, token kosong dan penolakan/malformed ACK. Jalankan scheme Xcode sesuai `docs/TESTING.md` untuk target iOS.
Harness pure Swift Linux tidak membuktikan UI, lifecycle coordinator PIN project utama, atau jaringan Byon nyata.
