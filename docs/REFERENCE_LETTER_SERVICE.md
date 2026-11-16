# Kontrak data dan service Surat Referensi

SDK menyediakan model form dan protocol `ReferenceLetterService`. Route endpoint, DTO request/response BE,
encoding/decoding, pemanggilan jaringan, pembentukan OTP, serta dekripsi email berada di project host. Pola ini
mengikuti pemisahan transport live agent: SDK memanggil kontrak host dan mengelola state tampilan. Service bisnis
Surat Referensi tetap terpisah dari `TanyaAIChatTransport`; tidak mengubah retry transport chat-gateway.

| Endpoint | Method | Kontrak |
| --- | --- | --- |
| `/user/tanya-ai/reference-letter/inquiry` | GET | Data pilihan, introduction, alamat, email terenkripsi, onlineSessionId |
| `/token/v4/verify/pin/otp` | POST | otpCode, challengeCode opsional, appliNumber, sequenceNumber |
| `/user/tanya-ai/reference-letter/ack` | POST | Pilihan dari inquiry, embassy, toggle, kontak asli, language, onlineSessionId, responseCodeOTP |

`ReferenceLetterInquiry` memakai `OptionItem` existing: `code` menjadi `id`, `value` menjadi `title`, dan description
rekening menjadi `subtitle` opsional. Default subtitle nil mempertahankan pemakai lama. Urutan BE dipertahankan;
ID kosong/ganda dinormalisasi sebelum sampai ke `ForEach`. Label, kode mata uang, dan nominal tidak dikarang atau
di-parse ulang oleh package.

`ReferenceLetterDraft` menyimpan kode pilihan dan input nasabah. Hanya tujuan dan format default ke elemen pertama
sesuai catatan BE. Field read-only email/alamat tetap pada inquiry. Snapshot ACK dibentuk hanya dari pilihan yang
masih tersedia dan input wajib yang valid; label serta deskripsi kembali ke BE persis dari hasil inquiry.
`ReferenceLetterRequest.email` selalu ciphertext asli, sementara `decryptedEmail` hanya untuk tampilan.

## Implementasi di project host

`TanyaAISandboxApp/ReferenceLetter` memuat contoh implementasi host: `ReferenceLetterServiceAdapter`, route
`ReferenceLetterEndpoint`, model wire inquiry/PIN/ACK, dan pemetaan error BE. Tipe-tipe ini internal pada project,
bukan API SDK. Host produksi dapat mengimplementasikan `ReferenceLetterService` langsung memakai model/service
yang sudah dimiliki; tidak perlu menyalin model wire sandbox bila sudah tersedia. Contoh pemasangan di host:

```swift
let referenceLetter = ReferenceLetterServiceAdapter(
    locale: locale,
    fallbackMessage: localizedServiceError,
    send: { endpoint, body in
        try await userService.request(path: endpoint.rawValue, method: endpoint.method, body: body)
    },
    preparePIN: { pin in
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
```

Nama service/properti token dalam contoh adalah titik pemetaan. Implementasi HTTP authenticated, generator OTP,
sequence/challenge, dan fungsi decrypt asli Byon tidak tersedia pada repository ini. Project produksi menyuntikkan implementasi
existing tersebut ke service host; tidak ada base URL, credential, algoritma crypto, atau generator token pengganti
di package. SDK menerima `ReferenceLetterInquiry`, hasil verifikasi, dan `ReferenceLetterReceipt` yang sudah
dipetakan. `ReferenceLetterRequest` adalah snapshot biasa tanpa `Encodable`; host mengubahnya menjadi body ACK.

PIN mentah bukan otomatis otpCode atau responseCodeOTP. Adapter meminta request token dan nilai ACK yang sesuai
dari host, mengirim verify, lalu hanya mengembalikan verifikasi pada `response_code == "00000"`.
05516 dipetakan menjadi PIN salah, 05005 menjadi terblokir, kode lain termasuk 05000/05006 menjadi error verifikasi.
HTTP 200 dengan business error tetap throw. Adapter ACK menerima snapshot serta hasil verifikasi secara terpisah
dan menolak token kosong. Bentuk JSON ACK, termasuk nama key dan responseCodeOTP, dimiliki DTO project host.

ACK sukses mengembalikan `ReferenceLetterReceipt` dari `data.title` dan `data.message`. Kegagalan parsing/transport
tidak diubah menjadi sukses atau di-retry otomatis. Orkestrasi pemanggilan verify sebelum ACK ditangani flow form
pada perubahan berikutnya. Tidak ada PIN di draft atau model request ACK, dan adapter tidak log body/token.

`TransactionPINRules` adalah aturan teknis enam angka ASCII yang dipakai service host dan keypad. Route dan
decoder pada project host serta aturan PIN masuk daftar metadata eksplisit pada guard design system, karena
memiliki route, key wire, dan konstanta kontrak. Package TanyaAI tidak memiliki route atau decoder endpoint form.

## Verifikasi

Unit tests mencakup default BE, daftar kosong, kode hilang, multi-select, snapshot request, ciphertext email,
pemetaan response_code, body verify dari generator host, dan nilai message ACK. Test Swift Testing disediakan
di target TanyaAI (model form) dan TanyaAISandboxTests (mapping serta service host). Jalankan scheme package
dan aplikasi host lewat Xcode/simulator sesuai `docs/TESTING.md`.

Validasi lokal dan batas lingkungan dicantumkan pada deskripsi PR. Build serta test UI iOS tetap membutuhkan
macOS/Xcode; validasi model di Linux tidak membuktikan layout atau integrasi service Byon sebenarnya.
