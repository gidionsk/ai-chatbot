# Starting point — aturan implementasi

Scope branch ini adalah migrasi bertahap: fondasi DesignKit, font package,
screen kosong dengan composer, dan shared header dengan boundary/blur scroll.
Konten dummy untuk mengecek scroll hanya berada pada sandbox. iOS 15. Gunakan SwiftUI; UIKit hanya untuk editor
multiline terukur, table daftar pesan (`ChatTable`) dan bridge presentasi terisolasi. Flow chat lengkap tetap
tersedia pada history/main.

## Header file

- Semua file kode yang dikelola repo (Swift, script, dan `.strings`) memiliki
  header nama file, module/package, dan `Created by Wendra on dd/MM/yy.`.
  File baru memakai tanggal pembuatan; jangan mengganti tanggal saat mengedit.
- `// swift-tools-version` dan shebang tetap pada baris pertama, sebelum header.
- Token generated juga memiliki header tersebut; perubahan ini hanya menambahkan
  header, tanpa mengubah token atau menghapus catatan asal/provenance. Saat export
  berikutnya, template engine perlu mengeluarkan header yang sama.
- Jangan menambahkan kredit pribadi ke lisensi/font pihak ketiga, binary,
  screenshot, atau file project yang dihasilkan Xcode/project generator.

## Token dan nilai

- `Tokens/Generated` milik export engine. Jangan edit manual atau menduplikasi
  nilainya. Gunakan satu sumber token/font untuk semua komponen.
- Padding/spacing memakai `FigmaSize.spacingSmall`, `spacingMedium`, `spacingLarge`,
  `spacingExtraLarge`, atau `spacingDoubleExtraLarge`, sesuai peran. Jangan memakai
  `spacing4/8/16/...`. Typography memakai nama role, bukan token numerik polos.
- Nilai desain di luar Figma dipisah per jenis, bukan dikumpulkan di satu file:

  | File | Isi | `.scaledToArtwork` |
  | --- | --- | --- |
  | `Generated/FigmaSize` | Spacing, ukuran icon, tipografi dari Figma. **Cek di sini dulu.** | Ya |
  | `CustomSizes` | Dimensi point yang belum ada di Figma: `Header` (padding), `Shadow`, `Composer.sendButton` | **Selalu** |
  | `CustomTextLines` | Batas baris per peran: `composerInput = 1...4`, `headerTitle` | Tidak pernah |
  | `CustomScreenInsets` | Padding atas header dari tepi layar, sama dengan navigation bar host (50/28) | Tidak pernah |
  | `CustomColors` / `CustomBasePaletteColor` | Warna semantik tambahan / hex dasarnya | — |
  | `ArtworkScale` | Referensi 375×812 dan rasio layar untuk `.scaledToArtwork` | Tidak pernah |
  | `LayoutTolerance` | Toleransi pembulatan layout (bukan token desain) | Tidak pernah |

  Nilai waktu/animasi custom masuk `CustomMotion` (tidak di-scale; dibuat lagi saat ada animasi).
  Animasi menghormati Reduce Motion.
  Kelompok bersama dinamai per peran (`Header`, `Shadow`, `CustomTextLines.address`
  bila nanti dibutuhkan). Nilai yang hanya dipakai satu komponen memakai namespace
  nama komponen (`CustomSizes.Composer`) agar terhapus bersama komponennya. Tambah
  nilai baru hanya ketika ada pemakainya. `check_design_system.py` menolak
  `CustomSizes` tanpa `.scaledToArtwork` dan baris/motion/toleransi/inset layar yang di-scale.
  Jangan membuat alias spacing generated atau memakai spacing sebagai radius.
- Nilai awal memakai nilai bawaan tipe: `.zero` untuk CGFloat/Int/TimeInterval,
  `String()` untuk string kosong, `[]` untuk koleksi. Tidak ada enum alias seperti
  `InitialValues`. Tulis tipe bila perlu: `var measuredHeight: CGFloat = .zero`.
  Boolean ditulis langsung `true`/`false`. Batas baris masuk `CustomTextLines`, dimensi
  masuk `CustomSizes`; konstanta algoritma yang bukan ukuran tetap private pada pemiliknya. UI/source
  tidak menuliskan literal angka/string default secara tersebar.
  `.zero`, `.infinity`, enum UIKit/SwiftUI dan Boolean control flow adalah nilai
  bernama/logika, bukan token desain baru. Bit mask/radix/ASCII di parser hex
  adalah algoritma format, bukan ukuran UI. Tests boleh memiliki fixture literal.
- `CustomBasePaletteColor` memiliki hex tambahan di luar palette generated.
  `CustomColors` mengatur penggunaan semantik/opacity. Warna yang sudah memiliki
  token Figma dipakai langsung; jangan disalin ulang sebagai custom color.
- `.scaledToArtwork`: round(nilai / `ArtworkScale.currentRatio`), rasio = 375 / lebar
  UIScreen.main, tanpa cap.
  Reference height 812 hanya metadata. Semua dimensi termasuk stroke dan area
  tombol memakai `.scaledToArtwork` langsung dari nilai desain. Jangan menambahkan
  batas minimum tap/stroke, hit frame tambahan, atau helper scaling terpisah.
  Ukuran interaksi mengikuti keputusan UI/UX. Opacity dan jumlah baris tidak
  di-scale. Tidak ada `sizeInArtwork` alias.

## Struktur TanyaAI

- Struktur dan aturan penempatan: [docs/PACKAGE_STRUCTURE.md](docs/PACKAGE_STRUCTURE.md).
  Pola: fungsi/pemilik → jenis file (`Models`, `Views`, `Controllers`, `Extensions`) → implementasi.
- `Bridging/`: konfigurasi host (`TanyaAIHost`) dan kontrak transport/error yang diimplementasi host.
- `Features/<Fitur>/`: screen di root fitur (`ChatScreen.swift`); bagian screen tetap di bawahnya:
  `Welcome/`, `Composer/`, `FollowUps/`. Welcome memiliki `Models/` dan `Views/` sendiri.
  Model dekat pemakainya; tidak ada folder Models/Views global untuk seluruh package.
  Bagian satu file seperti Composer/FollowUps tetap sederhana. `Welcome` bukan fitur tersendiri.
- `Chat/Messages`: nilai/merge pesan dan tampilan bubble. `Chat/ConversationList`: penyusunan baris,
  tanggal, hosting table, dan scroll. Di dalamnya: `Models`, `Views`, `Controllers`, `Extensions`, `Formatting`.
  Jangan menaruh seluruh logic daftar di `Messages`.
- `Chat/Session`: `TanyaAIBridge` dan state/connection/turn. Bridge tetap public dan dibuat sekali oleh host.
  `Chat/Gateway`: format respons, decoding, history, dan framing SSE; HTTP tetap milik host.
- `Chat/Keys`: `ChatCopy`, `ChatImage`, `ChatElementIdentifier` serta accessor terkait. Jangan membuat
  `Shared` sebelum ada beberapa fitur yang benar-benar memakai fungsi yang sama.
- Intent belum diputuskan. Rancangannya ada di `docs/PACKAGE_STRUCTURE.md` dan dikonfirmasi ke user saat Figma
  dan contract flow pertama ada. Jangan menambah folder kosong atau BaseIntent sebelum itu.
- `Resources/`: aset dan lokalisasi saja, tanpa file Swift. Tests mencerminkan folder Sources;
  helper test di `Support/`.

## Font, resource, copy

- Font berada di `Resources/Fonts`; filename dan PostScript di `FontFace`.
  SwiftUI memakai `face.swiftUIFont(size:)`; `font(size:)` (`UIFont`) hanya untuk UIKit/editor.
  Register sekali saat bootstrap melalui CoreText/`Bundle.module`, idempotent.
- Nama case menyertakan family dan weight: `firaSansRegular/Medium/SemiBold/Bold`
  dan `openSansRegular/Medium/Bold`. Jangan memakai case `.regular/.medium` yang
  ambigu antar-family. Tambahkan file asli beserta lisensi dan nama PostScript
  yang dibaca dari metadata; jangan menyamakan nama file dengan PostScript.
- Semua teks memakai Fira Sans. Open Sans belum dipakai: case dan file-nya hanya
  cadangan, jangan menjadi default komponen atau dipakai di layar.
- Typography memakai token `FigmaSize` yang sudah berpasangan per role, misalnya
  `typographySizeDisplaySmall14` dengan `typographyLineHeightDisplaySmall14`, dan
  `FontFace` eksplisit. Composer memakai Display Small 14/21, hanya dengan `.scaledToArtwork`. Ukuran font/leading tidak mengikuti
  pengaturan Dynamic Type pengguna; jangan menambahkan `@ScaledMetric` atau
  UIFontMetrics. Editor dan placeholder menerima UIFont fixed yang sama.
  Glyph Chinese yang tidak ada di Fira Sans menggunakan fallback native iOS.
- Copy fitur berada di resource `en`, `id`, `zh-Hans`. Screen membaca locale dari
  environment dan menyuplai label ke DesignKit. Tidak ada copy bisnis di DesignKit.
- Tanpa R.swift dan tanpa build tool plugin (CI host tidak bisa trust plugin). Key copy
  ditulis di satu enum per pemilik resource: `ChatCopy` (TanyaAI), `SandboxCopy` (sandbox);
  ikon DesignKit di `DesignIcon` (template) dan `DesignColorIcon` (berwarna utuh, nama aset Byon).
  Pakai `String(ChatCopy.send, locale: locale)` dan `Image(DesignIcon.backArrow)`.
  Menambah string/ikon = tambah entri di resource + case di enum; tes memastikan
  key enum sama persis dengan isi `Localizable.strings` ketiga bahasa dan imageset.
- Technical identifiers, filename/PostScript font dan diagnostic prefix tetap
  metadata eksplisit. Artwork sementara mempunyai TODO penggantian.
- Theme memakai environment SwiftUI standar, tanpa ThemeManager/singleton.
  Komponen membaca `@Environment(\.designColors) private var colors`; jangan
  menerima parameter `colors:` atau membuat `DefaultColorConstants()` sendiri.
  Untuk Tanya AI, host mengisi `colors` dan `locale` pada `TanyaAIHost` (inquiry
  proposition, Localize_Swift); nilainya dibaca saat halaman dibuat, tanpa live update.
  Screen DesignKit lain memasang `.designColors(_:)` di root-nya.
  Area yang harus bebas theme memakai `.defaultDesignColors()` pada subtree itu.
  CopyCatalog belum diperlukan.

## Komponen dan ownership

- DesignKit `Components/<Fungsi>`: `Actions`, `Images`, `Inputs`, `Lists`, `Markdown`, `Messages`, `Screen`.
  Komponen beberapa file memakai subfolder sendiri; satu file langsung di kelompok fungsinya.
  Bagian beberapa file dikelompokkan ke `Models`, `Views`, `Controllers`, `Protocols`, `Extensions` sesuai peran.
  Helper/model/extension khusus komponen tetap dalam pemilik itu, seperti `Markdown/Models` dan `Markdown/Views`.
  `Foundations` berisi `Typography`, `Iconography`, `Appearance`, `Accessibility`.
  `Extensions/<Type>+<Responsibility>.swift` hanya untuk utilitas lintas komponen. Modifier card/shadow
  dan palette environment berada di `Foundations/Appearance/ViewModifiers` dan `Extensions`.
  Extension implementasi satu tipe tetap bersamanya (parser di Parsing, controller di Controllers);
  extension accessor/transform seperti Array+ChatMessage masuk Extensions. Jangan membuat folder jenis yang kosong.
  Nama DesignKit umum, tanpa prefix fitur. Jangan membuat ViewModel per komponen.
- Identifier UI test dikelompokkan per komponen (`ComponentIdentifier.Header.title`,
  `ComponentIdentifier.Composer.send`). String identifier adalah kontrak UI test.
- Tidak ada alias untuk nilai sistem: `.clear`, bukan `CustomColors.transparent`.
- TanyaAI dipisah per tanggung jawab (lihat "Struktur TanyaAI"). Folder intent baru dibuat saat file
  pertamanya ada, bukan lebih awal.
- Screen standar memakai composition `ScreenScaffold` dari DesignKit: header, trailing action, footer, dan
  latar. Scroll milik konten, yang melaporkan `scrollProgress`; `ChatScreen` memakai ini dengan `ChatTable`.
  Aturan table ada di `docs/REVAMP_NOTES.md`. Jangan membuat inheritance/BaseScreen protocol, ViewModel layout
  atau navigation container tambahan. Footer memiliki margin sesuai komponen caller.
- `ScreenHeader` tetap komponen standalone untuk layout dengan scroll owner lain
  seperti List. Label/aksi back dan trailing berasal dari caller. Ukuran sama dengan
  navigation bar host: mulai dari tepi atas layar (caller menaruhnya tanpa safe area atas,
  `isNotched` dari `ScreenHeader.isNotched(safeAreaTop:)`), padding atas 50/28 tanpa scale,
  kiri-kanan 20, bawah 15, ikon 24, judul Fira Sans Bold 16 dengan padding 32.
- `.onScrollBoundaryChange(in:threshold:perform:)` reusable di DesignKit. Pasang
  pada root konten scroll setelah padding; ID sama dengan ScrollView owner.
  Callback memberi nilai awal lalu perubahan Boolean saja, tanpa state offset
  setiap pixel, global PreferenceKey atau AnyView. Jaga isolasi nested scroll.
- Utamakan API SwiftUI sederhana yang familiar bagi tim. Untuk identitas area
  scroll, gunakan `@State private var scrollSpaceID = UUID()`, tanpa `@Namespace`.
  State mempertahankan nilai ID selama view yang sama hidup. Jangan membuat ID
  baru di body atau memakai satu ID global untuk beberapa area scroll. Tambahkan
  konsep/property wrapper lain hanya ketika ada kebutuhan yang jelas.
- Header chat belum punya aksi kanan; menu "Percakapan baru" dihapus (28 Oktober 2026) sampai ada
  kebutuhan dan alur BE (batas 1 percakapan per CIF, close). Jangan menambah intent atau database
  sebelum diminta.
- Welcome berasal dari BE, tapi decode milik host: `WelcomeContent`/`WelcomeGreeting`/`WelcomeShortcut`
  (folder `Features/Chat/Welcome/`) adalah struct biasa tanpa `Decodable`. Host memetakan model
  inquiry init miliknya ke tipe ini; `iconURL` nil memakai ikon fallback. Contract chat-gateway ICT
  (init chat, history, SSE) di-decode TanyaAI (`Features/Chat/Gateway`). Shortcut dikirim lewat bridge.
- `TanyaAIBridge` (`Features/Chat/Session`) dipegang host selama halaman terbuka bersama `TanyaAIChatTransport`
  (per endpoint, body mentah, non-2xx = `TanyaAITransportError.response`). Bridge menjalankan
  init → history → SSE lewat `.task`, backoff 1–30 detik tanpa batas, merge history berdasarkan
  `message_id`, dan `Last-Event-ID` = seq terbesar. Pesan hanya tampil dari stream; `isAwaitingReply`
  dari kirim sampai `turn_end`; satu pertanyaan per waktu. Detail: `docs/CHAT_GATEWAY.md`.
- Gambar dari URL memakai `RemoteImage` DesignKit, pembungkus tipis `KFImage` Kingfisher
  (cache memori + disk, downsample ke `pointSize` × skala layar, validasi status HTTP,
  batal saat view hilang). Kingfisher hanya di-import di `RemoteImage`; fitur lain memakai
  `RemoteImage`, bukan `KFImage`/`AsyncImage` langsung. Versi Kingfisher dikunci `exact`
  di `Package.swift` DesignKit; naik versi hanya lewat PR yang mengubah baris tersebut.
- `let` untuk input, `@Binding` untuk state caller, `@State` untuk draft lokal.
  Screen memiliki margin luar; komponen memiliki padding dalam/surface/shadow.
  Kartu dan bayangan memakai `.cardStyle()`/`.designShadow()` dari DesignKit; jangan
  menyusun ulang radius, garis tepi, atau shadow di setiap view.
- Callback sederhana ditulis langsung (`() -> Void`, `(String) -> Bool`) dengan
  nama aksi dan kontrak hasil yang jelas. Typealias hanya untuk signature kompleks
  atau kontrak domain bersama, diletakkan dekat pemiliknya, bukan catalog global.
  Potongan yang baru mungkin reusable tetap private sampai tanggung jawab/caller
  berikutnya jelas; ekstrak komponen umum yang memang diperlukan.
- Tinggi editor satu sampai empat baris; teks berikutnya scroll. Ukuran tombol
  mengikuti nilai desain, tanpa minimum tap tambahan. Kata panjang dan keyboard
  tidak menggeser action keluar.
- Composer memakai alignment bawah dengan minimum tinggi row yang sama pada
  field dan tombol: satu baris sejajar tengah, multiline mempertahankan tombol
  di bawah. Tinggi row satu baris mengikuti font/leading dan ukuran visual tombol;
  jangan menambahkan state jumlah baris untuk mengubah alignment.
- Padding composer di semua sisi dan jarak field/tombol memakai `spacingLarge`
  (16 pada artwork 375), tanpa kompensasi area tap. Frame tombol mengikuti ukuran
  visual desain. Pengaturan ukuran teks pengguna tidak mengubah tinggi row atau
  batas empat baris composer.
- Hint memakai font input yang sama dan alignment `.leading` pada ZStack agar
  berada di tengah field saat kosong. Pertahankan geometri caret native pada
  semua state: kosong, mengetik dan sesudah hapus. Jangan memusatkan caret kosong
  secara terpisah ke bounds, karena referensinya berbeda dari baseline saat mengetik.
- Draft dimiliki `ComposerSection` (`@State`), bukan `ChatScreen`, agar setiap ketikan
  tidak me-render ulang header dan daftar pesan; draft dikosongkan bila chat diterima.
  Jangan log isi pesan.
- Jaringan milik host lewat `TanyaAIChatTransport` (init, history, SSE, kirim). TanyaAI decode
  contract dan mengatur sesi di `TanyaAIBridge`; pesan berupa value type (`ChatMessage`) ber-ID
  stabil. Kontrak: `docs/CHAT_GATEWAY.md`.
- Integrasi host: `TanyaAIHost` hanya konfigurasi (`locale`, `colors`, `service`) dan
  `makeView()` berupa view SwiftUI. Host menampilkannya lewat navigasinya sendiri
  (host SwiftUI: coordinator + destination dengan `@StateObject`, swipe-back bawaan). Package
  tidak membuat modal, transisi custom, NavigationView/NavigationStack, atau toolbar
  native. Tombol back memanggil `onBack`, atau `dismiss` SwiftUI bila tidak diisi.
  Blocker host (no internet, session expired) tampil di atas halaman ini tanpa kode
  di package. `TanyaAIHost` adalah struct konfigurasi yang dibuat saat halaman dibuka.
- UI owners `@MainActor`; putus delegate pada dismantle dan hindari retain cycle.
- Tidak ada angka/string literal di kode package selain file definisi: token
  (`Tokens/`), metadata font (`FontFace`), identifier UI test, dan spesifikasi format
  hex (`HexFormat` private di `Color+Hex`). Arah dan rentang dihitung dari nilai yang
  ada (lebar layar, arah layout, `.zero`), bukan konstanta `1`/`-1`.
- Tanpa forcing di source maupun test: tidak ada `!` unwrap, `as!`, `try!`, atau
  tipe `Type!`. SwiftLint (`force_unwrapping`, `implicitly_unwrapped_optional`,
  `force_cast`, `force_try`) menolaknya. Property UIKit bertipe IUO seperti
  `UITextView.text` dibaca sebagai optional (`editor.text ?? String()`), jangan
  di-override atau dipakai langsung sebagai non-optional. Unit test memakai
  `try #require(...)`; UI test memakai `let application = XCUIApplication()` dan
  `XCTUnwrap`, bukan IUO di `setUp`.
- Unit test (package dan `TanyaAISandboxTests`) memakai Swift Testing: `struct` suite,
  `@Test`, `#expect`, `try #require`, dan `arguments:` untuk kasus berulang. UI test
  (`TanyaAISandboxUITests`) tetap XCTest karena XCUITest belum ada di Swift Testing.
  Swift Testing menjalankan test paralel: tunggu kondisi async dengan `waitUntil`
  (`Task.sleep`, bukan RunLoop); suite yang membuka window atau menunggu sambil
  memegang window diberi `@Suite(.serialized)`, dan di sandbox masuk lewat
  `extension HostWindowTests`. Butuh Xcode 16 ke atas.
- Private view sections berupa noun: `field`, `surface`, `actionButton`.
  Deklarasi utama berurutan environment, binding/state, input, init, body, sections.
  Computed setup/perhitungan/validasi berada di `private extension` pada file yang
  sama, dengan `// MARK: - Helpers`. Handler memakai `// MARK: - Actions` dan
  private extension tersendiri bila ada. Stored properties/property wrapper tetap
  pada deklarasi utama; jangan mengubahnya menjadi computed hanya agar pindah.
  Lifecycle protocol/override UIKit tetap pada tipe pemilik. Jangan membuat
  extension kosong atau memisahkan setiap helper menjadi extension sendiri.
- Ikuti [template view](docs/VIEW_TEMPLATE.md). Property wrapper SwiftUI standar,
  `@ViewBuilder`, `@MainActor`, dan `@main` pada app mempunyai peran jelas.
  Jangan menambahkan macro kustom, `@Observable`/`@Model`, wrapper baru atau
  inheritance hanya untuk menyeragamkan layout.
- Tanpa `if ... else`: pakai `if A { return A }` lalu `return B`, `continue` di dalam loop, atau `switch`.
  Pengecualian: di dalam `@ViewBuilder` yang tidak bisa `return` lebih awal, dan `guard ... else`.
- Atribut variabel satu baris dengan variabelnya: `@Environment(\.designColors) private var colors`.
- Maksimal 250 baris/file, 50 baris fisik/method, 120 karakter/baris; Bool berawalan
  `is`, kecuali nama wajib protocol seperti `PreferenceKey.defaultValue` dengan
  pengecualian lint lokal beralasan. Jangan padatkan implementasi agar lolos batas.

## Validasi

- Format: `python3 Scripts/format_changed.py --base startingpoint`.
- Style: `Scripts/check_style.sh`; semua checks: `Scripts/verify.sh`.
- Regenerate project lewat `ruby Scripts/generate_project.rb`; jangan edit pbxproj.
- PR untuk tahap ini menuju `startingpoint`, bukan `main`. Jangan memasukkan
  session SDK, bubble, PreviewBook atau transaksi ke starter sebelum diminta.
