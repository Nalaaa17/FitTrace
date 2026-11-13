# Rencana Phase Pengerjaan — FitTrace

Acuan implementasi bertahap berdasarkan [PRD_FitTrace.md](../PRD_FitTrace.md) dan keputusan arsitektur di [ADR.md](ADR.md).

---

## Phase 0 — Project Foundation, Database Drift & App Shell
**Target:** Fondasi proyek Flutter + Riverpod, skema Drift (SQLite), tema monokrom, dan kerangka navigasi.
**Cakupan PRD:** `NFR-05`, §4, §6

### Tugas
- [x] Inisialisasi proyek Flutter (`com.fittrace.app`) dan struktur monorepo mini (`lib/` + `packages/metrics_engine/`).
- [x] Susun arsitektur *feature-first* (`presentation / application / domain / data`) dengan Riverpod.
- [x] Setup logger global dengan *secret scrubber* (`NFR-02`) dan tipe error domain.
- [x] Implementasi tema monokrom Dark (default: `#0A0A0A` / `#161616`) & Light (`#FFFFFF` / `#F4F4F4`), tipografi `Space Grotesk` / `Inter` + `FontFeature.tabularFigures()`.
- [x] Implementasi navigasi 3 tab utama (`Feed`, `Stats`, `Settings`) + Splash & Onboarding skeleton.
- [x] Implementasi skema **Drift (SQLite)** v1 (`activities`, `track_points`, `lap_splits`, `user_preferences`) sesuai ADR-001 & ADR-002 + unit test CRUD & migrasi dasar.

### Exit Gate
- [x] `flutter analyze` dan `flutter test` lulus tanpa error (11/11 test Flutter + 4/4 test `metrics_engine`).
- [ ] Uji build/run langsung di emulator atau device Android (menunggu konfirmasi perangkat uji).

---

## Phase 1 — Pure Dart FIT Parser & Running Metrics Engine
**Target:** Package `metrics_engine` murni Dart untuk mem-parse file `.FIT` dan menghitung seluruh metrik lari.
**Cakupan PRD:** `M2-01` s.d. `M2-09`, `NFR-03` (isolate), `NFR-05`

### Tugas
- [x] Integrasi `fit_tool` pada `packages/metrics_engine` (verifikasi bebas dependensi Flutter).
- [x] Ekstrak record `session`, `lap`, `record`, `activity`, dan `hrv` (simpan mentah).
- [x] Konversi koordinat semicircle → derajat desimal + validasi range (`M2-02`).
- [x] Filter GPS spike (`> 15 m/s` atau `> 2×` sustained pace, tandai `gpsQuality: degraded`).
- [x] Algoritma **Moving Time** (`< 0.5 m/s` berturut-turut `>= 10s`, smoothing window `±3` titik) (`M2-03`).
- [x] Algoritma **Elevation Gain** ter-smooth (`window 5 titik`, threshold `0.5 m`) (`M2-05`).
- [x] Agregasi **Split per 1.000 m** (pace, moving time, avg HR, avg cadence, elevasi Δ) (`M2-04`).
- [x] Kalkulasi **HR Zone 1–5** dengan fallback ADR-004 (`hrMaxManual` → `220 - umur` → default `190 bpm`).
- [x] Penanganan aktivitas indoor (`isIndoor = true`) dan aktivitas tanpa data HR (`M2-08`, §7).
- [x] Siapkan suite test fixture 8 skenario (5K outdoor, marathon >30k titik, treadmill indoor, tanpa HR, GPS spike, korup parsial, lintas zona waktu).

### Exit Gate
- [x] Coverage unit test `metrics_engine` `>= 90%` (terukur **95.69%**, 422/441 baris); semua 18 unit/fixture test lulus via `dart test`.

---

## Phase 2 — Manual Import, Activity Feed & Detailed Analytics UI
**Target:** Aplikasi 100% fungsional secara offline lewat impor `.FIT` manual, lengkap dengan feed, peta, dan grafik analisis.
**Cakupan PRD:** `M1-05`, `M1-08`, `M1-09`, `M3-01` s.d. `M3-07`, `NFR-01` (v1)

### Tugas
- [x] Buat abstraksi `ActivityImportSource` (siap dipakai ulang oleh Garmin Sync di Phase 3).
- [x] Impor manual via `file_picker` (multi-select) + Android Share Intent (`ACTION_SEND` / `ACTION_SEND_MULTIPLE`).
- [x] Pipeline import: streaming SHA-256 dedup → arsip `.fit.gz` internal (retensi 30 hari) → parse di `Isolate` → transaksi simpan ke Drift (`Activity`, `TrackPoint`, `LapSplit`).
- [x] **Activity Feed:** Paging 30 item dari SQLite, badge `SYNCED` / `LOCAL_ONLY` / `FAILED`, filter (tanggal, jenis lari, sumber), thumbnail polyline statis `200×120 px` ter-cache di disk.
- [x] **Kartu Agregat & Tab Stats (`M3-07`):** Statistik Mingguan/Bulanan via query agregasi SQLite.
- [x] **Detail Screen:**
  - Header hero numbers (jarak, moving time, avg pace)
  - Peta `flutter_map` + OSM tile cache lokal + polyline gradient by pace + mode panel *"Indoor Activity"*
  - Grafik sinkronisasi crosshair (Pace, Elevasi, HR) yang terhubung dengan marker posisi di peta
  - Tabel splits horizontal-scrollable (aksen best split) & bar distribusi HR Zone 1–5.

### Exit Gate
- [x] Impor massal `.FIT` (termasuk marathon 31.000 trackpoints, indoor, korup/gagal parse, dedup SHA-256) terverifikasi non-blocking via test unit/pipeline & `flutter analyze --no-pub` / `flutter test --no-pub` lulus (14/14).
- [ ] Uji interaktif `file_picker` & Android Share Intent (`ACTION_SEND` / `ACTION_SEND_MULTIPLE`) langsung di emulator/device Android nyata.

---

## Phase 3 — Garmin Connect Sync Engine
**Target:** Sinkronisasi otomatis & manual dari akun Garmin Connect pengguna lewat internet (Wi-Fi maupun data seluler).
**Cakupan PRD:** §2.2, §2.3, `M1-01` s.d. `M1-07`, `NFR-02`, `NFR-03` (burst/rate-limit)

### Tugas
- [x] Flow Onboarding lengkap (Carousel 3 halaman, izin runtime non-blocking, pilihan Login Garmin vs *Manual Import Only*).
- [x] Embedded WebView SSO Garmin (`webview_flutter`) + penyimpanan kredensial/cookie terenkripsi di `flutter_secure_storage` + fallback WebView user-resolvable jika muncul tantangan CAPTCHA/Cloudflare.
- [x] Session probe (`401/403` → banner re-login, `429` → backoff eksponensial hingga 5x) + silent auto-refresh.
- [x] Sync Engine (`Dio` HTTPS strict, tanpa logging kredensial): fetch activity list (50/halaman), dedup `garminActivityId` + hash, download burst maks 10 FIT dengan jeda 2 detik, retry 3x (`2s→4s→8s`), penanganan `ENOSPC` & status `syncFailed`.
- [x] Auto-sync saat app dibuka/resume dengan threshold responsif **`> 5–15 menit`** + debounce 60 detik (ADR-003).

### Exit Gate
- [x] Sinkronisasi 55 aktivitas (30+) tanpa duplikat, ZIP/FIT unwrap, retry 429 & 3x backoff download, penanganan `ENOSPC`, alur session expired + banner re-login, ADR-003 auto-sync/debounce, dan redaksi token/cookie di `AppLogger.scrub` terverifikasi lewat `flutter analyze --no-pub` & `flutter test --no-pub` (24/24 lulus).
- [ ] Uji login WebView SSO & sinkronisasi live langsung ke akun Garmin Connect pada emulator/device Android nyata.

---

## Phase 4 — Instagram Story Generator & Native Sharing
**Target:** Generator kartu statistik 9:16 (`1080×1920`) dengan sharing langsung ke Instagram Stories.
**Cakupan PRD:** §2.5, `M4-01` s.d. `M4-07`, ADR-005

### Tugas
- [x] Render kanvas `1080×1920` tepat via `RepaintBoundary` (`toImage`) untuk PNG latar & stiker RGBA transparan.
- [x] 3 Template MVP:
  - **Template A — Route Glow:** Latar gelap + efek glow/gradient pada polyline rute.
  - **Template B — Photo Overlay:** Foto galeri (crop 9:16) + gradient gelap 60% + stiker metrik transparan.
  - **Template C — Minimalist Metrics:** Grid angka monokrom penuh tanpa peta.
- [x] Editor interaktif: drag, pinch-to-zoom, rotasi opsional, toggle metrik, bobot font & alignment.
- [x] Native `MethodChannel` (`com.fittrace.app/story_share`): Android (`com.instagram.share.ADD_TO_STORY` + `FileProvider`) & iOS (`instagram-stories://share` + `UIPasteboard`).
- [x] Fallback *"Simpan ke Galeri"*, draft cache toast saat dibatalkan, serta cleanup cache PNG >24 jam.

### Exit Gate
- [x] Render & ekspor PNG `1080×1920` (latar + stiker RGBA transparan), 3 template, gesture & styling editor, fallback dialog + draft toast, cleanup cache >24 jam, serta kontrak `MethodChannel` terverifikasi via `flutter analyze --no-pub` & `flutter test --no-pub` (27/27 lulus).
- [ ] Uji handoff Intent/URL Scheme langsung ke aplikasi Instagram fisik pada perangkat Android (dan iOS bila tersedia).

---

## Phase 5 — Optimasi Skala Marathon, Backup/Restore & MVP Release Prep
**Target:** Memenuhi seluruh target performa (`NFR-01`–`NFR-04`), melengkapi manajemen data lokal, dan rilis MVP v1.0.
**Cakupan PRD:** `M5-01` s.d. `M5-04`, `NFR-01` s.d. `NFR-04`, `Settings`

### Tugas
- [x] **Optimasi Performa (`NFR-01`):**
  - Douglas-Peucker polyline decimation di `Isolate` per zoom-bucket + cache hasil
  - Split polyline per km (`<= 42` segmen)
  - Downsampling grafik min/max bucket (`<= 1.000` titik)
  - Tile cache LRU eviction maks 100 MB, [ ] profiling RAM (`< 256 MB` peak), frame rate (`>= 55 FPS`) & cold start (`<= 1.5s`) pada perangkat fisik Android/iOS.
- [x] **Manajemen Data (`M5-01`–`M5-04`):**
  - Ekspor ulang ke `.FIT` (dari `.fit.gz` 30 hari atau regenerasi record biner untuk aktivitas lama)
  - Backup penuh ke ZIP (`backup.json` + `trackpoints.bin` + folder FIT) tanpa cookie/kredensial
  - Restore ZIP dengan validasi versi skema & merge anti-duplikat
  - Hapus aktivitas tunggal & Factory Reset double-confirm.
- [x] Halaman **Settings** lengkap (HRmax/umur, unit Metric/Imperial, tema, status koneksi Garmin, kebijakan jaringan sync, backup/restore).
- [x] Persiapan rilis store sebagian (ikon adaptif monokrom Android, copy/metadata listing, dokumen Privacy Policy local-only); [ ] capture screenshot monokrom dari build perangkat nyata.

### Exit Gate — MVP v1.0 Ship
- [x] Benchmark pipeline geometri marathon 45K (`Isolate` Douglas-Peucker 3 zoom bucket, `<= 42` segmen, `<= 1.000` titik grafik), tile LRU eviction, serta round-trip ekspor `.FIT` & backup/restore ZIP terverifikasi otomatis tanpa kehilangan data (`flutter test`: `33/33`, `metrics_engine` `dart test`: `22/22`).
- [ ] Uji performa perangkat fisik: aktivitas marathon 42K merender peta `<= 2 detik` pada `>= 55 FPS`, peak RAM `< 256 MB`, cold start `<= 1.5s`, dan capture screenshot monokrom untuk store listing.

---

## Phase 6 — Post-MVP Enhancements (V1.1)
**Target:** Otomatisasi background sync (termasuk via data seluler tanpa wajib charging) & analitik pelari lanjutan.
**Cakupan PRD:** `M1-10`, `M1-11`, `M2-10`, `M2-11`, `M3-08`, `M3-09`, `M4-08`, `M4-09`, `M5-05`, `M5-06`, ADR-003

### Tugas
- [x] **Background Sync (`WorkManager` / `BGTaskScheduler`):** Interval periodik (min 15 menit Android) dengan default mendukung **data seluler + Wi-Fi** dan **tidak wajib charging** (disertai opsi hemat kuota/baterai di Settings).
- [x] **Incremental Sync (`M1-11`):** Fetch `startTime > lastActivityStartTime - 24h` & preservasi custom title lokal saat re-sync.
- [x] Best Effort PR detection (5K, 10K, HM, FM) + estimasi VO2max (VDOT) & race predictor (`M2-10`, `M2-11`).
- [x] Pencarian feed, rename aktivitas lokal, dan streak calendar heatmap 20 minggu (`M3-08`, `M3-09`).
- [x] Preset layout Story custom & toggle watermark `FitTrace` (`M4-08`, `M4-09`).
- [x] Statistik storage + `VACUUM` / compact SQLite, pengingat backup bulanan, & ekspor CSV (`M5-05`, `M5-06`).

### Exit Gate
- [x] Seluruh skenario pengujian unit & integrasi Phase 6 lulus otomatis (`phase6_enhancements_test.dart` 4/4 passed, `metrics_engine` 25/25 passed, zero static analysis issues).


