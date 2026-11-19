# Contoh lokal Form Surat Referensi

Contoh ini untuk project pribadi Anda, mengikuti API PR #74 (`342c4e4`) pada repo Wendra.
File contoh disimpan di Examples/ReferenceLetterForm dan tidak masuk target build SDK.
Salin file ke project lokal Anda untuk menjalankannya.

## Penempatan file

Salin semua 8 file `.swift` ke dalam target **TanyaAI**, misalnya:

`Packages/TanyaAI/Sources/TanyaAI/Features/Chat/Intents/Form/Demo/`

Jangan letakkan file ini di target aplikasi Byon atau target test. `IntentFormView`, `FormField`, dan
`IntentFormState` adalah tipe internal, sehingga contoh harus berada dalam module TanyaAI yang sama.
Tidak perlu membuat tipe SDK menjadi public atau memakai `@testable import`.

Project ini menggunakan Swift package lokal; file di Sources/TanyaAI ditemukan otomatis oleh SwiftPM.
Contoh mengasumsikan API `IntentFormState(fields:)` dan `FormFieldCondition`, seperti di foto Anda.
Contoh ini tidak ditujukan untuk branch eksperimen `init(rules:)`.

## Menampilkan di LiveAgentMessageRow seperti foto

### 1. ChatScreen menyimpan state satu halaman

Di `ChatScreen.swift`, tambahkan property ini bersama property state lainnya:

```swift
@State private var referenceLetterDemo = ReferenceLetterDemoState()
```

`@State` menjaga referensi objek selama halaman hidup. View form dan presenter mengamati objeknya,
sehingga root tidak perlu mengamati semua ketikan lewat `@StateObject`.

### 2. Pasang sheet pada root halaman

Pada `body` ChatScreen, tambahkan modifier pada hasil `ScreenScaffold`, bukan pada baris table:

```swift
.modifier(ReferenceLetterDemoSheetPresenter(demo: referenceLetterDemo))
```

Contoh posisi pada rantai modifier yang sudah ada:

```swift
.overlay { loadingIndicator }
.modifier(ReferenceLetterDemoSheetPresenter(demo: referenceLetterDemo))
.task { await bridge.run() }
```

Sheet membuka pilihan satu/banyak melalui IntentFormOptions existing, lalu menutup setelah pilihan diterima.

### 3. Teruskan objek ke row hosting

Di fungsi `ChatScreen.listRow`, tambahkan `.environmentObject(referenceLetterDemo)` pada hasil ChatListRow.
Pada versi #74, fungsi lengkapnya menjadi:

```swift
private func listRow(_ item: ChatListItem, actions: ChatRowActions) -> some View {
    ChatListRow(item: item, welcome: welcome, content: content, actions: actions)
        .id(item.id)
        .designColors(colors)
        .environment(\.locale, locale)
        .environmentObject(referenceLetterDemo)
}
```

Langkah ini wajib: row dihosting melalui UIKit table dan tidak otomatis mewarisi environment halaman.
Tanpanya, EnvironmentObject tidak ditemukan ketika form ditampilkan.

### 4. Ganti body LiveAgentMessageRow sementara

```swift
var body: some View {
    ReferenceLetterDemoForm()
}
```

Hapus percobaan `var state = ...` dan `presentation` dari screenshot. State dan label sudah disediakan
oleh file contoh. Semua id memakai enum yang sama dan IntentFormView memiliki generic eksplisit,
sehingga tidak bergantung pada inferensi tipe dari id String yang belum lengkap.

LiveAgentMessageRow hanya dirender ketika ada pesan agen. Setiap pesan agen akan menampilkan form yang
sama selama body-nya diganti dengan demo ini. Ini pemasangan sementara untuk mengecek tampilan.

## Melihat langsung tanpa menunggu agen

Alternatif tercepat: setelah menyalin 8 file, sementara ganti body `ChatScreen` menjadi:

```swift
public var body: some View {
    ReferenceLetterDemoPage()
}
```

Halaman ini sudah memiliki state dan root sheet sendiri. Tidak perlu langkah pemasangan pada row di atas.
Halaman hanya berisi form yang bisa di-scroll; header/composer chat tidak ditampilkan pada jalur ini.
Tidak menjalankan bridge/service. Jalankan aplikasi Byon seperti biasa dan buka halaman TanyaAI.

## Data dan perilaku dummy

- Awal: Pengajuan VISA, Softcopy, Kedutaan Amerika Serikat, rekening pertama, IDR.
- Ada tiga rekening untuk mencoba ringkasan “Terpilih 3 rekening”.
- Saldo aktif dan investasi nonaktif. Toggle serta teks kedutaan dapat diedit.
- Softcopy menampilkan email; Hardcopy menampilkan alamat. Keduanya tidak bisa diedit, mengikuti catatan BE.
- Email yang tampil berasal dari `decryptedEmail`, bukan placeholder `encryptedEmail`.
- Kirim menjalankan validasi IntentFormView. Jika valid, hanya muncul “Data form sudah valid (demo).”
- Untuk mencoba error, kosongkan kedutaan atau hapus seluruh centang rekening lalu tekan Kirim.
- Batalkan mereset form melalui state existing.

Contoh ini tidak memanggil PIN, verifikasi, atau ACK. Ini fixture visual, bukan definisi aturan intent produksi.
Perubahan tujuan belum mereset semua field di bawahnya; perilaku itu masuk scope IntentFormRules terpisah.
Copy dummy disimpan di file contoh agar mudah disalin. Untuk kode produksi, pindahkan copy ke resource
lokalisasi sesuai aturan repository.

## Mengapa kode di foto bermasalah

1. Ada `FormField(id: ...)` yang belum diisi. Ini membuat compiler gagal menentukan tipe FieldID dan bisa
   menampilkan error lanjutan pada closure presentation.
2. Semua id dalam satu form harus memiliki tipe yang sama. Contoh memakai ReferenceLetterDemoField.
3. `.constant(state)` menghasilkan binding yang tidak menyimpan perubahan. Contoh memakai `$demo.form`.

## Validasi contoh

File Swift diperiksa format, sintaks, dan batas panjang kode. Lima test data/state lulus terhadap model
form aktual dari PR #74: nilai awal, email/alamat nonaktif, validasi kosong, urutan multi-rekening,
dan reset. Build SwiftUI, simulator dan tampilan visual masih
perlu dijalankan di Xcode; tidak diklaim sudah berhasil dibuild pada iOS.
