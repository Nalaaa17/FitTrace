# PRODUCT REQUIREMENTS DOCUMENT (PRD)

# FitTrace — Local-First Garmin Running Analytics & Instagram Story Sharing

| | |
|---|---|
| **Nama Produk** | FitTrace |
| **Versi Dokumen** | 1.0 (Baseline untuk MVP & V1.1) |
| **Status** | Ready for Engineering |
| **Penulis** | Senior Technical Product Manager / Lead Mobile Architect |
| **Platform** | Android (prioritas) & iOS — Flutter |
| **Arsitektur** | 100% Local-First, Offline-Ready, tanpa backend server |

---

# 1. Executive Summary & Product Vision

## 1.1 Visi Produk

FitTrace adalah aplikasi mobile analisis lari **local-first** yang memberdayakan pelari pengguna jam tangan Garmin untuk: (a) menarik data aktivitas langsung dari Garmin Connect tanpa server perantara, (b) mengurai file `.FIT` menjadi metrik analitik yang kaya, dan (c) membagikan hasil lari mereka ke Instagram Stories dengan kartu statistik estetis — semuanya **dengan privasi data penuh** karena seluruh data disimpan secara lokal di perangkat.

## 1.2 Masalah yang Dipecahkan

| Masalah | Solusi FitTrace |
|---|---|
| Platform analisis lari (Strava, dsb.) memerlukan akun cloud, biaya langganan, dan membawa data keluar dari perangkat | Arsitektur lokal penuh — zero server, zero biaya berlangganan infrastruktur |
| Garmin Connect app UX analisis dinilai terbatas dan kurang fokus pada pelari | Analytics engine khusus lari: pace per km, HR zones, elevasi, splits |
| Pelari ingin pamer rute/stats ala Strava tanpa ekosistem sosial yang ramai | Share-to-Story langsung ke Instagram, tanpa feed sosial internal |
| Ketergantungan koneksi internet untuk melihat riwayat lari | Offline-ready total: database lokal + tile peta ter-cache |

## 1.3 Proposisi Nilai Unik (UVP)

1. **Privasi absolut**: data GPS & detak jantung tidak pernah meninggalkan perangkat (kecuali oleh kehendak pengguna saat share ke Instagram).
2. **Zero-cost infrastructure**: tidak ada backend, API server, atau database cloud yang harus dioperasikan/dibiayai.
3. **Analisis khusus pelari Garmin**: parser FIT native, split otomatis per kilometer, HR Zone 1–5.
4. **Story-ready output**: generator kartu 9:16 monokrom yang langsung terkirim ke Instagram Stories.

## 1.4 Non-Goals (Di Luar Cakupan)

- ❌ Sosial feed, komunitas, komentar, atau segment leaderboard internal.
- ❌ Backend server / REST API milik sendiri.
- ❌ Sinkronisasi lintas perangkat (multi-device sync).
- ❌ Analisis olahraga selain lari (sepeda, renang, gym) pada MVP — parsing tetap menyimpan data mentahnya, tapi UI analytics difokuskan ke lari.
- ❌ Integrasi Wear OS / Apple Watch companion app.
- ❌ Upload otomatis ke Garmin Connect (aplikasi bersifat read-only terhadap Garmin).

---

# 2. User Personas & Core User Flows

## 2.1 Personas

**Persona A — "Rani, 28, Urban Runner"**
- Pemakaian: Garmin Forerunner, lari 4–5x/minggu, jarak 5–21K.
- Pain point: ingin rekap mingguan yang rapi, benci notifikasi feed sosial.
- Kebutuhan: pace per km, HR zones, kartu story estetis.

**Persona B — "Bagas, 35, Marathoner"**
- Pemakaian: Garmin Fenix, lari ultra/marathon, sering di area sinyal lemah.
- Pain point: rute marathon 42K lambat dirender di aplikasi lain; butuh akses data offline di gunung.
- Kebutuhan: rendering polyline performa tinggi >30.000 titik, cache peta offline, backup manual.

## 2.2 Core User Flow 1 — Onboarding & Login Garmin (First Run)

```
Splash (logo monokrom, 800ms)
  → Onboarding Carousel (3 halaman: Privasi Lokal / Analisis Garmin / Story Sharing)
  → Izin Runtime:
      • Lokasi (ACCESS_FINE_LOCATION) — dipinta saat parsing FIT dengan catatan,
        bukan wajib untuk fungsi inti
      • Notifikasi (opsional, untuk status sinkronisasi background)
      • Storage (Android 12 ke bawah, untuk impor FIT manual)
  → Pilihan Auth:
      [A] Login Garmin Connect (Embedded WebView Interception)
      [B] Lewati dulu → mode "Manual Import Only"
  → (Jalur A) WebView membuka https://connect.garmin.com/signin
      → Interceptor menangkap cookie session (GARMIN-SSO, SESSION, etc.)
      → Validasi session: GET /activitylist (probe) → 200 = sukses
      → Cookie disimpan ke flutter_secure_storage (Keychain/Keystore)
      → Halaman "Sinkronisasi Pertama" otomatis berjalan
  → Home: Activity Feed (kosong → empty state dengan CTA "Sinkronkan")
```

**Acceptance criteria:**
- Login berhasil dalam ≤3 langkah UI (buka webview → kredensial → selesai).
- Gagal probe session → tampil error actionable, cookie tidak disimpan.
- Jika pengguna memilih [B], fitur sinkronisasi Garmin disembunyikan dari UI sampai login dilakukan.

## 2.3 Core User Flow 2 — Sinkronisasi (Otomatis & Manual)

```
Pemicu sinkronisasi (pilih satu):
  • Pull-to-refresh di Feed
  • Tombol "Sinkronkan" (FAB)
  • App open (jika lastSync > 6 jam) — debounce 60 detik
  • Background fetch (opsional, WorkManager/API 15 menit) — V1.1

Langkah Engine:
  1. Ambil cookie dari secure storage → validasi TTL/probe.
     └─ Jika expired: [Auto-refresh attempt via WebView silent]
        → masih gagal: kirim user ke re-login (banner persisten)
  2. GET daftar aktivitas terbaru (activity list API, limit 50/halaman).
  3. Untuk setiap aktivitas: cek dedup key = (garminActivityId).
     └─ Sudah ada di DB & hash FIT sama → skip.
     └─ Sudah ada tapi hash beda → tandai `needsReparse`, unduh ulang.
     └─ Belum ada → download binary .FIT.
  4. Parse FIT via fit_tool → INSERT ke Isar (Activity, TrackPoint, LapSplit) dalam 1 transaksi/aktivitas.
  5. Update lastSyncAt, tampilkan ringkasan: "X aktivitas baru • Y diperbarui • Z dilewati".
```

## 2.4 Core User Flow 3 — Analisis Pasca-Lari

```
Feed → tap aktivitas
  → Detail Screen (scroll vertikal):
      1. Header: judul, tanggal, dist/time/pace besar (hero numbers)
      2. Peta: polyline rute, start/finish marker, gradient by pace
      3. Grafik interaktif (sync-crosshair): Pace, Elevasi, Heart Rate
         — satu canvas dengan crosshair terkunci per jarak
      4. Splits table: per km → pace, HR avg, elevasi Δ
      5. HR Zone distribution: bar 5 zone dengan durasi & persen
      6. Aksi: [Buat Story Card] [Ekspor FIT] [Hapus]
```

## 2.5 Core User Flow 4 — Share to Instagram Story

```
Detail Aktivitas → "Buat Story Card"
  → Template Picker (3 template: Route Glow / Photo Overlay / Minimalist Metrics)
  → Editor: pilih background (foto galeri / peta rute), atur posisi & ukuran
    stiker statistik (drag + pinch), pilih metrik yang tampil
  → Preview 9:16
  → "Bagikan ke Instagram"
      1. RepaintBoundary → toImage() → PNG 1080x1920 → file di app cache
      2. Cek package com.instagram.android (Android) / canOpenURL (iOS)
      3. Android: intent com.instagram.share.ADD_TO_STORY
         (setBackgroundAsset + setStickerAsset, contentURL opsional)
         iOS: URL Scheme instagram-stories://share + pasteboard items
      4. File cache PNG dihapus setelah 24 jam (cleanup job)
      5. Fallback: "Simpan ke Galeri" + toast instruksi manual upload
```

---

# 3. Functional Requirements

## Modul 1 — Garmin Sync & Manual Import Engine

| ID | Requirement | Prioritas |
|---|---|---|
| M1-01 | Embedded WebView (`webview_flutter`) membuka halaman login SSO resmi Garmin; interceptor network menangkap `Set-Cookie` pada respons sign-in sukses. | MVP |
| M1-02 | Cookie disimpan terenkripsi di `flutter_secure_storage` (Android Keystore / iOS Keychain). Tidak ada cookie yang ditulis ke Isar/disk biasa. | MVP |
| M1-03 | Session probe: request ringan ke activitylist; interpretasi 401/403 sebagai session expired; 429 sebagai rate-limit (backoff eksponensial maks 5x). | MVP |
| M1-04 | Auto-refresh session: silent WebView (headless, tidak di-render) mencoba refresh cookie sekali sebelum menyatakan expired. | MVP |
| M1-05 | **Deduplikasi**: unik key `(garminActivityId)` pada koleksi `Activity`; sebelum unduh, bandingkan `fitFileHash` (SHA-256). | MVP |
| M1-06 | Unduh `.FIT` via `dio` + `dio_cookie_manager`; stream bytes → hash sambil unduh → simpan sementara → parse → commit DB → hapus temp file (FIT asli tetap dapat diregenerasi via ekspor). | MVP |
| M1-07 | Retry policy: 3x dengan exponential backoff (2s→4s→8s) untuk network error; gagal total → status aktivitas `syncFailed` dengan pesan error yang dapat ditindaklanjuti. | MVP |
| M1-08 | **Manual Import**: file picker (`file_picker`) untuk multi-select `.FIT`; terima Android Share Intent (`ACTION_SEND`/`ACTION_SEND_MULTIPLE`) saat pengguna membuka file .FIT dari app lain (WhatsApp, Files, dsb.). | MVP |
| M1-09 | Activity indicator di feed: badge `SYNCED` / `LOCAL_ONLY` / `FAILED`. | MVP |
| M1-10 | Background sync via WorkManager (Android, min 15 menit, hanya saat Wi-Fi + charging, opt-in) dan BGTaskScheduler (iOS). | V1.1 |
| M1-11 | Incremental sync: hanya fetch aktivitas dengan `startTime > lastActivityStartTime - 24h` (buffer overlap untuk aktivitas yang ter-edit). | V1.1 |

## Modul 2 — FIT Binary Parser & Running Metrics Engine

| ID | Requirement | Prioritas |
|---|---|---|
| M2-01 | Parser berbasis `fit_tool` memproses semua record: `session`, `lap`, `record` (trackpoints), `activity`, `hrv` (simpan mentah). | MVP |
| M2-02 | Konversi koordinat: semicircles × (180 / 2³¹) → derajat desimal (double). Validasi range lat [-90,90], lng [-180,180]; drop titik invalid. | MVP |
| M2-03 | **Moving time**: algoritma deteksi berhenti — kecepatan < 0.5 m/s berturut-turut ≥10 detik dianggap diam (dengan toleransi GPS jitter via smoothing window ±3 titik). | MVP |
| M2-04 | **Split per km**: agregasi trackpoints per interval 1000 m; tiap split berisi: distance, moving time, avg pace, avg HR, avg cadence, elevasi Δ. | MVP |
| M2-05 | Elevasi: total gain dihitung hanya dari kenaikan positif ter-smooth (window 5 titik, threshold minimal 0.5 m) untuk menekan noise altimeter. | MVP |
| M2-06 | **HR Zones 1–5**: zona dihitung dari `HRmax` = 220 − umur (default; dapat diubah user di Settings, juga input HRmax manual). Batas default: Z1 <60%, Z2 60–70%, Z3 70–80%, Z4 80–90%, Z5 ≥90%. Durasi per zona dari timestamp trackpoints. | MVP |
| M2-07 | Pace: `paceSecPerKm = movingTime / distance`; tampilkan format `MM'SS"`/km. | MVP |
| M2-08 | Parser bersifat toleran: file tanpa GPS (indoor run) tetap diproses — flag `isIndoor = true`, peta diganti tampilan "Indoor — no route", metrik lain normal. | MVP |
| M2-09 | Cache hasil kalkulasi berat (splits, zones) di field denormalized pada `Activity` agar detail screen tidak re-hitung setiap buka. Recompute hanya jika ada reparse. | MVP |
| M2-10 | Best effort detection (5K, 10K, HM, FM) dari history — highlight di feed & detail. | V1.1 |
| M2-11 | Estimated VO2max & race predictor (sederhana, formula berbasis VDOT-lite) — diberi label "estimasi". | V1.1 |

## Modul 3 — Activity Feed & Detailed Analytics UI

| ID | Requirement | Prioritas |
|---|---|---|
| M3-01 | Feed: ListView dengan paging (Isar pagination 30 item) berisi: tanggal, judul, dist/pace/HR ringkas, thumbnail peta statis (polyline prerender 200x120px, cache di disk). | MVP |
| M3-02 | Filter feed: rentang tanggal, jenis aktivitas (lari/interval/indoor), sumber (synced/import). | MVP |
| M3-03 | Peta detail: `flutter_map` + OSM tiles dengan cache lokal (`flutter_map_cache` / `cached_network_image` tile provider); polyline utama dengan gradient warna berbasis pace (scale hitam→abu→putih pada tema gelap, diberi aksen tajam). | MVP |
| M3-04 | Grafik interaktif: satu canvas custom painter (atau `fl_chart`) menggabungkan Pace, Elevasi, HR dengan dual/triple axis; crosshair tersinkron saat drag; tap memilih titik → menampilkan nilai + posisi di peta (highlight marker). | MVP |
| M3-05 | Split table horizontal-scrollable per km dengan best-split diberi aksen. | MVP |
| M3-06 | HR Zone bar: 5 segmen proporsional durasi, label % + waktu, dengan legenda Z1–Z5. | MVP |
| M3-07 | Statistik mingguan/bulanan: kartu agregat di atas feed (dist total, rata-rata pace, total moving time, aktivitas count) dengan toggle Minggu/Bulan; state disimpan di `UserPreferences`. | MVP |
| M3-08 | Pencarian & rename aktivitas (judul custom tersimpan lokal, override judul Garmin). | V1.1 |
| M3-09 | Heatmap/ kalender konsistensi (GitHub-style streak calendar). | V1.1 |

## Modul 4 — Instagram Story Card Generator

| ID | Requirement | Prioritas |
|---|---|---|
| M4-01 | Kanvas rasio 9:16 tepat 1080×1920 px, di-render via `RepaintBoundary` + `toImage(pixelRatio: ...)` menjadi PNG RGBA (transparan untuk sticker asset). | MVP |
| M4-02 | **Template A — Route Glow**: background gelap; polyline rute diberi efek *glow* (blur/gradient stroke); statistik besar di bawah (Distance hero, pace, time, tanggal). | MVP |
| M4-03 | **Template B — Photo Overlay**: background foto dari galeri pengguna (crop center 9:16); overlay gradient hitam (60% opasitas, dari bawah); stiker statistik transparan diletakkan atas foto; pengguna dapat drag & pinch stiker. | MVP |
| M4-04 | **Template C — Minimalist Metrics**: background putih bersih / hitam pekat; grid angka monokrom tipografi besar; tanpa peta. | MVP |
| M4-05 | Setiap template: pengaturan posisi & ukuran stiker statistik (drag, pinch-to-zoom, rotate opsional), toggle visibilitas per metrik (dist, pace, time, HR avg, elevasi, tanggal, judul), pilihan font-weight & alignment. | MVP |
| M4-06 | **Native share Instagram**: Android — Intent `com.instagram.share.ADD_TO_STORY` dengan `contentUri` background asset (FileProvider) + sticker asset + `com.instagram.platform.extra.APPLICATION_ID`. iOS — `instagram-stories://share` + UIPasteboard (com.instagram.sharedSticker.backgroundImage / stickerImage). | MVP |
| M4-07 | Fallback saat Instagram tidak terpasang: dialog "Instagram tidak ditemukan" dengan aksi "Simpan ke Galeri" (PNG disimpan via `gallery_saver`/MediaStore) + petunjuk manual. | MVP |
| M4-08 | Preset watermark: toggle logo kecil "FitTrace" (posisi pojok, dapat dimatikan di Settings). | V1.1 |
| M4-09 | Template custom user: simpan konfigurasi layout (posisi/ukuran/toggle metrik) sebagai preset yang dapat dipakai ulang. | V1.1 |

## Modul 5 — Local Data Management & Backup

| ID | Requirement | Prioritas |
|---|---|---|
| M5-01 | **Ekspor FIT asli**: setiap aktivitas dapat diekspor kembali menjadi file `.FIT` (data trackpoints diregenerasi ke format FIT via penulisan ulang record, atau menyimpan blob asli bila tersedia di cache — implementasi: simpan blob FIT asli terkompresi di disk internal dengan path tersimpan di `Activity.originalFitPath`, default retain 30 hari terakhir; aktivitas lama diregenerasi). | MVP |
| M5-02 | **Backup penuh**: ekspor seluruh DB ke satu file ZIP berisi `backup.json` (metadata, splits, prefs) + `trackpoints.bin` (binary compact) + folder FIT; progres ditampilkan; share via file picker/ShareSheet. | MVP |
| M5-03 | **Restore**: impor ZIP backup dengan validasi skema & versi; merge strategy: `garminActivityId` yang sama → skip (tidak duplikat); transaksi tunggal per batch. | MVP |
| M5-04 | **Delete**: hapus aktivitas (konfirmasi dialog; hapus trackpoints & blob terkait dalam 1 transaksi); hapus semua data (factory reset lokal dengan double-confirm). | MVP |
| M5-05 | Statistik storage di Settings: ukuran DB, jumlah aktivitas & trackpoints, tombol "Compact DB" (Isar compact). | V1.1 |
| M5-06 | Auto-backup reminder: notifikasi lokal bulanan jika backup terakhir >30 hari. | V1.1 |

---

# 4. Data Models & Local Database Schema (Isar)

> **Catatan**: Isar bersifat NoSQL berbasis objek; skema di bawah adalah kontrak logis. Jika drift/SQLite dipilih, skema ekuivalen: tabel `activities`, `track_points`, `lap_splits`, `user_preferences` dengan index yang sama.

### 4.1 Collection `Activity`

```dart
@collection
class Activity {
  Id isarId = Isar.autoIncrement;          // PK lokal

  @Index(unique: true)
  int garminActivityId;                    // dedup key; 0 untuk import manual tanpa ID

  String title;                            // override lokal, default dari Garmin
  int sportType;                           // enum SportType { run=1, trailRun, treadmill, other }
  DateTime startTimeLocal;
  int durationTotalSec;                    // elapsed time
  int durationMovingSec;                   // moving time (M2-03)
  double distanceMeters;
  double avgPaceSecPerKm;
  double? avgHeartRate;
  double? maxHeartRate;
  double? avgCadence;
  double totalElevationGainM;
  double totalElevationLossM;
  int caloriesKcal;

  bool isIndoor;                           // tanpa data GPS valid
  bool hasGpsTrack;
  String source;                           // enum { garminSync, manualImport }
  String syncStatus;                       // enum { synced, localOnly, failed }
  String? originalFitPath;                 // path blob FIT asli di disk internal
  String fitFileHash;                      // SHA-256 untuk dedup (M1-05)

  // Denormalized (hasil kalkulasi berat, M2-09)
  List<int> splitPacesSecPerKm;            // per km
  List<int> zoneDurationsSec;              // 5 elemen, Zone1..Zone5

  DateTime createdAt;
  DateTime updatedAt;
}
```

### 4.2 Collection `TrackPoint`

```dart
@collection
class TrackPoint {
  Id isarId = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('timestamp')])
  int activityId;                          // FK → Activity.isarId

  DateTime timestamp;
  double latitudeDeg;                      // hasil konversi semicircle (M2-02)
  double longitudeDeg;
  double altitudeM;
  double speedMps;
  int? heartRateBpm;                       // null jika sensor tidak ada
  int? cadenceRpm;
  int distanceMeters;                      // kumulatif dari FIT
  short? hrZone;                           // 1..5 (dihitung saat parse)

  // Kompaksi: simpan sebagai @embedded list di Activity untuk <5.000 titik
  // (fast load), dan sebagai collection terpisah untuk aktivitas besar —
  // kebijakan threshold di NFR-01.
}
```

> **Strategi penyimpanan trackpoints**: aktivitas ≤5.000 titik → embedded list (1 read). >5.000 titik → koleksi `TrackPoint` tersendiri dengan index `(activityId, timestamp)`; lazy-load segmen saat render grafik, decimation untuk peta.

### 4.3 Collection `LapSplit`

```dart
@collection
class LapSplit {
  Id isarId = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('splitIndex')])
  int activityId;

  int splitIndex;                          // km ke-N (0-based)
  double distanceMeters;
  int durationSec;
  double avgPaceSecPerKm;
  double? avgHeartRate;
  double? avgCadence;
  double elevationDeltaM;
}
```

### 4.4 Collection `UserPreferences` (singleton, id=1)

```dart
@collection
class UserPreferences {
  Id id = 1;                               // singleton

  // Garmin auth
  bool garminLoggedIn;
  DateTime? lastSyncAt;
  DateTime? lastActivityStartTime;         // untuk incremental sync

  // Profil & zona HR
  DateTime? birthDate;                     // untuk HRmax default (privasi: lokal saja)
  int? hrMaxManual;                        // override 220-umur
  List<int> hrZoneThresholds;              // default [60,70,80,90] (% HRmax)

  // UI
  String themeMode;                        // system | dark | light (default dark)
  String unitSystem;                       // metric | imperial
  String weeklyMonthlyToggle;              // feed stats default

  // Story generator
  bool watermarkEnabled;
  String defaultTemplateId;                // routeGlow | photoOverlay | minimalist

  // Backup
  DateTime? lastBackupAt;
}
```

### 4.5 Diagram Relasi (ringkas)

```
Activity 1 ──── n TrackPoint
Activity 1 ──── n LapSplit
Activity 1 ──── 1 UserPreferences (independen, singleton)
```

---

# 5. Non-Functional Requirements

### NFR-01 — Performa Rendering Polyline Skala Marathon

- Aktivitas 42K full → ~30.000–45.000 trackpoints harus tampil dalam **≤2 detik first paint peta** dan **FPS ≥ 55** saat interaksi.
- Teknik wajib:
  1. **Decimation/line-simplification**: Douglas-Peucker (tolerance dinamis 1–5 m berdasar zoom level) dijalankan isolate compute; hasil disimpan cache per zoom-bucket, bukan recompute tiap frame.
  2. Segmen polyline per split-km (42 segmen) dengan color per pace — menghindari satu PolylinePainter raksasa; memudahkan gradient per segmen.
  3. Embedded vs koleksi terpisah (lihat §4.2) — hindari membaca 45.000 objek sekaligus ke memory.
  4. Grafik pace/HR/elevasi di-*downsample* ke maks 1.000 titik tampilan (min/max bucket per bin).

### NFR-02 — Keamanan Penyimpanan Kredensial

- Cookie Garmin hanya di `flutter_secure_storage` (Android Keystore AES-256 / iOS Keychain kSecAttrAccessibleAfterFirstUnlock).
- Tidak ada logging cookie/token ke console, analytics, atau crash report. Scrubber pada logger global.
- Export/backup **tidak pernah** menyertakan cookie.
- TLS pinning tidak dipakai (resiko break saat rotasi sertifikat Garmin), namun seluruh traffic wajib HTTPS (dio `BadCertificateCallback` → reject all).
- Tidak ada PII tambahan yang dikumpulkan; birthDate opsional & hanya lokal.

### NFR-03 — Baterai, Memori, & Storage

- Sinkronisasi batch maks 10 FIT per burst; jeda 2 detik antar burst — menahan thermal & rate-limit.
- Background sync hanya saat charging + Wi-Fi (M1-10).
- Memory: peak < 256 MB saat membuka aktivitas marathon (profil di dev build dengan `debugPrint`s).
- Storage: target < 300 MB untuk 200 aktivitas dengan trackpoints penuh (estimasi blob FIT + Isar + tile cache masing-masing dibatasi 100 MB; tile cache LRU eviction).
- Parser berjalan di isolate (`compute()` / Isolate.run) — UI tidak jank saat import 20 FIT sekaligus.

### NFR-04 — Reliabilitas & Availability

- Aplikasi 100% fungsional offline: feed, detail, peta (dari cache), generator story (kecuali langkah kirim ke Instagram).
- Crash-free sessions ≥ 99,5% (target internal via Crashlytics — hanya metadata teknis, tanpa data aktivitas).
- Cold start ≤ 1,5 detik di perangkat mid-range (Pixel 6 class).

### NFR-05 — Maintainability

- Arsitektur: feature-first layering (presentation / application / domain / data) dengan Riverpod.
- Parser & metrics engine murni Dart, tanpa dependency Flutter → unit-testable penuh.
- Contract test untuk parser: suite fixture FIT (5K luar, treadmill indoor, tanpa HR, korup parsial).

---

# 6. UI/UX Design Guidelines

### 6.1 Palet Warna Monokrom

| Token | Light | Dark (default) | Pemakaian |
|---|---|---|---|
| `bgBase` | `#FFFFFF` | `#0A0A0A` | background utama |
| `bgElevated` | `#F4F4F4` | `#161616` | card, bottom sheet |
| `textPrimary` | `#0A0A0A` | `#F5F5F5` | angka metrik, judul |
| `textSecondary` | `#5C5C5C` | `#9E9E9E` | label, tanggal |
| `accentSharp` | `#000000` | `#FFFFFF` | garis grafik, polyline pace terbaik, border tajam |
| `accentMetric` | `#2E2E2E` | `#E8E8E8` | highlight data (best split) |

- **Tanpa warna selain grayscale** — kecuali satu aksen opsional di grafik HR (mis. grayscale ramp penuh; HR zone boleh diberi intensitas hitam berbeda). Ekspektasi "data-centric monokrom" dijaga konsisten hingga ke ikon dan illustration.
- Polyline peta: gradient hitam→putih (dark mode) searah pace; start marker lingkaran putih, finish marker bendera hitam-putih.

### 6.2 Tipografi (angka metrik adalah hero)

| Elemen | Font | Ukuran | Weight |
|---|---|---|---|
| Hero number (distance) | Space Grotesk / Inter | 56 sp | 700 |
| Pace besar | 40 sp | 600 | |
| Label metrik | 12 sp | 500, letter-spacing 0.08em, UPPERCASE | |
| Split table | 14 sp | 500 (tabular nums wajib `fontFeatures: [tnum]`) | |
| Grafik axis | 10 sp | 400 | |

- Gunakan `fontFeatures: [FontFeature.tabularFigures()]` pada SEMUA angka yang berubah (timer, pace, grafik) agar tidak jumpy.

### 6.3 Navigasi Utama

- **Bottom Navigation 3 tab**: `Feed` | `Stats` (agregat mingguan/bulanan & PR) | `Settings`.
- Detail aktivitas: full-screen route push dengan hero transition dari thumbnail feed.
- Generator story: bottom sheet → full-screen editor (immersive, chrome disembunyikan).
- Prinsip: konten data selalu full-bleed, margin 16 dp, card radius 12 dp, border 1 dp `accentSharp` 12% opasitas.

---

# 7. Edge Cases & Error Handling

| Skenario | Detekksi | Handling UX |
|---|---|---|
| Session Garmin kedaluwarsa | Probe 401/403 | Banner persisten di feed: "Sesi Garmin berakhir — hubungkan ulang" → tap membuka WebView re-login; selama ini mode manual import tetap jalan |
| Cookie invalid / parsing cookie gagal | Interceptor kosong / probe gagal | Treat sebagai belum login; jangan crash; clear entry storage |
| Rate limit Garmin (429) | Status code | Backoff eksponensial maks 5 percobaan (1m, 5m, 15m, 30m, 60m); notifikasi "Sinkronisasi ditunda" |
| File FIT korup | fit_tool throw / CRC gagal | Tandai aktivitas `parseFailed`; tampilkan di feed dengan badge merah tipis (grayscale outline) + aksi "Coba lagi" / "Hapus"; jangan blokir aktivitas lain |
| FIT tanpa GPS / indoor | 0 titik valid post-validasi (M2-02) | `isIndoor=true`; peta diganti panel "Indoor Activity"; elevasi dari alat jika ada; split tetap dari jarak sensor |
| FIT tanpa HR data | field HR kosong di semua record | Grafik HR disembunyikan; ringkasan menampilkan "—"; HR zones kosong |
| Instagram tidak terpasang | Package check / canOpenURL | Dialog fallback → "Simpan ke Galeri" + toast langkah manual |
| Share Instagram dibatalkan user | Result cancelled | Tetap simpan PNG di cache 24 jam; toast "Kartu tersimpan di draft" |
| Izin storage/lokasi ditolak | Permission denial | Fit terdegradasi secara elegan: manual import via SAF tetap mungkin; tidak ada hard-block |
| Restore backup versi skema lebih baru | Versi skema di header backup | Tolak dengan pesan jelas "Backup dibuat versi aplikasi lebih baru (vX)" |
| Storage penuh saat download FIT | IOException ENOSPC | Pause sync; notifikasi "Penyimpanan penuh"; tampilkan tip cleanup di Settings |
| Trackpoint loncat ganas (GPS spike >15 m/s lari) | Validasi antar-titik | Drop titik outlier (kecepatan > 2× pace rata-rata sustained); flag `gpsQuality: degraded` |
| Jam zona waktu berubah / lintas zona waktu | startTimeLocal vs UTC | Selalu simpan UTC + offset lokal; tampilan pakai waktu lokal aktivitas |
| Pengguna uninstall tanpa backup | — | Onboarding V1.1: banner halus "Data hanya tersimpan di perangkat ini. Buat backup." |

---

# 8. Development Roadmap & Milestones

### Fase 0 — Foundation (Minggu 1–2)
- Setup project Flutter, arsitektur feature-first + Riverpod, CI (analyze/test/build), theming monokrom, navigasi 3 tab, Isar schema v1 + migration harness.
- **Gate**: app shell jalan; skema DB tervalidasi; test harness parser siap.

### Fase 1 — FIT Parser & Metrics Engine (Minggu 2–4)
- Integrasi `fit_tool`, konversi semicircle, validasi, moving time, splits, HR zones, indoor handling, GPS spike filter.
- Unit test: ≥90% line coverage pada engine; fixture 8 skenario.
- **Deliverable**: library `metrics_engine` murni Dart + laporan uji fixture.

### Fase 2 — Manual Import + Feed + Detail (Minggu 4–7)
- File picker + share intent, dedup hash, Isar write pipeline, feed dengan paging & thumbnail prerender, detail screen (peta polyline sederhana, grafik crosshair v1, splits, HR zones).
- **Gate**: pengujian internal dengan 50 FIT asli dari 2 perangkat tester.

### Fase 3 — Garmin Sync Engine (Minggu 7–9)
- WebView interception + secure storage, session probe & auto-refresh, pull + incremental list, FIT download pipeline dengan retry/backoff, dedup & failed states.
- **Gate**: end-to-end sync 30 aktivitas pertama tanpa duplikat; expired-session flow teruji (force logout dari Garmin web).

### Fase 4 — Story Generator & Native Share (Minggu 9–11)
- 3 template, editor drag/pinch, RepaintBoundary → PNG 1080×1920, FileProvider, intent Android & URL scheme iOS, fallback save-to-gallery, cache cleanup.
- **Gate**: share sukses ke Instagram Stories di 3 device Android berbeda + 1 iOS.

### Fase 5 — Polish, NFR & Store Prep (Minggu 11–12) → **MVP Release**
- Decimation polyline & downsample grafik (NFR-01), isolates & battery pass, backup/restore ZIP, Settings lengkap, copywriting store, screenshot asset monokrom, privacy policy (open-source style, tanpa data collection).
- **MVP v1.0 ship.**

### V1.1 (Minggu 13–16, post-MVP)
- Background sync (WorkManager/BGTaskScheduler), best-effort detection & PR highlight, VO2max/race predictor (berlabel estimasi), template preset & watermark toggle, streak calendar, storage stats & compact, auto-backup reminder, ekspor CSV.
- **V1.1 ship** dengan feedback loop dari user MVP (in-app survey opsional, lokal).

### Risiko Teknis Utama & Mitigasi

| Risiko | Mitigasi |
|---|---|
| Garmin mengubah alur SSO / menambah proteksi → WebView interception rusak | Jalur manual import sebagai mode permanen; monitor komunitas open-source Garmin API; desain sync engine sebagai interface yang dapat diganti provider-nya |
| Cloudflare/CAPTCHA di WebView | Deteksi halaman challenge → tampilkan WebView full user-resolvable (bukan silent); fallback ke manual import |
| Perubahan ToS Garmin terkait scraping | FitTrace bersifat personal-use, read-only, resmi via sesi pengguna sendiri; dokumentasikan di store listing; siapkan mode "Import Only" satu-tap |

---

*Dokumen ini adalah acuan tunggal untuk implementasi. Setiap penyimpangan dari requirement di atas wajib didiskusikan dan dicatat sebagai Engineering Decision Record (ADR) singkat.*
