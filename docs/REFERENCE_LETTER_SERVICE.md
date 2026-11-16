# Kontrak data dan service Surat Referensi

Bagian ini menyediakan model dan adapter untuk tiga endpoint BE. UI form, keypad, serta pemasangannya di chat
berada pada perubahan terpisah. Tidak ada perubahan pada transport chat-gateway.

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

## Adapter

Host dapat mengimplementasikan `ReferenceLetterService` langsung, atau menyuntikkan fungsi existing ke
`ReferenceLetterServiceAdapter`:

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
sequence/challenge, dan fungsi decrypt asli Byon tidak tersedia pada repository ini. Host menyuntikkan implementasi
existing tersebut; tidak ada base URL, credential, algoritma crypto, atau generator token pengganti di package.

PIN mentah bukan otomatis otpCode atau responseCodeOTP. Adapter meminta request token dan nilai ACK yang sesuai
dari host, mengirim verify, lalu hanya mengembalikan verifikasi pada `response_code == "00000"`.
05516 dipetakan menjadi PIN salah, 05005 menjadi terblokir, kode lain termasuk 05000/05006 menjadi error verifikasi.
HTTP 200 dengan business error tetap throw. Adapter ACK menolak snapshot tanpa token verifikasi.

ACK sukses mengembalikan `ReferenceLetterReceipt` dari `data.title` dan `data.message`. Kegagalan parsing/transport
tidak diubah menjadi sukses atau di-retry otomatis. Orkestrasi pemanggilan verify sebelum ACK ditangani flow form
pada perubahan berikutnya. Tidak ada PIN di draft atau model request ACK, dan adapter tidak log body/token.

`TransactionPINRules` adalah aturan teknis enam angka ASCII yang dipakai adapter dan nantinya keypad; file ini
tidak menggambar komponen baru. Model request/decoder dan aturan PIN masuk daftar metadata eksplisit pada guard
design system karena memiliki route, key wire, dan konstanta kontrak, bukan ukuran atau copy UI.

## Verifikasi

Unit tests mencakup default BE, daftar kosong, kode hilang, multi-select, snapshot request, ciphertext email,
pemetaan response_code, body verify dari generator host, dan nilai message ACK. Test Swift Testing disediakan
di target DesignKit/TanyaAI. Jalankan scheme package lewat Xcode/simulator sesuai `docs/TESTING.md`.

Validasi lokal dan batas lingkungan dicantumkan pada deskripsi PR. Build serta test UI iOS tetap membutuhkan
macOS/Xcode; validasi model di Linux tidak membuktikan layout atau integrasi service Byon sebenarnya.
