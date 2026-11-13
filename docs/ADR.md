# Engineering Decision Records (ADR) — FitTrace

Dokumen ini mencatat keputusan arsitektur dan penyimpangan resmi terhadap [PRD_FitTrace.md](../PRD_FitTrace.md) (sesuai aturan pada bagian penutup PRD).

---

## ADR-001 — Pemilihan Database Lokal: Drift (SQLite) Menggantikan Isar

- **Status:** Disetujui
- **Referensi PRD:** §4 (catatan skema ekuivalen Drift/SQLite), `M3-07`, `NFR-01`
- **Keputusan:** Menggunakan **Drift (SQLite)** sebagai database lokal utama menggantikan Isar.
- **Alasan:**
  1. Stabilitas build pada Flutter/Dart SDK modern (Dart 3.13.x) dan Android Gradle Plugin 8+ tanpa isu kompatibilitas native library.
  2. Mendukung query agregasi SQL secara langsung untuk kartu statistik mingguan/bulanan (`M3-07`) tanpa memuat seluruh objek ke memori.
  3. Menyederhanakan penyimpanan `TrackPoint` menjadi satu tabel terindeks `(activity_id, timestamp)` dan *lazy/decimated loading*, menggantikan pemisahan `@embedded` vs `@collection` untuk batas 5.000 titik.
- **Konsekuensi:** Skema logis `Activity`, `TrackPoint`, `LapSplit`, dan `UserPreferences` pada PRD §4 dipetakan ke tabel relasional `activities`, `track_points`, `lap_splits`, dan `user_preferences` dengan index yang setara.

---

## ADR-002 — Skema Deduplikasi `garminActivityId` Nullable + Hash SHA-256

- **Status:** Disetujui
- **Referensi PRD:** §4.1 (`Activity.garminActivityId`), `M1-05`, `M1-08`
- **Penyimpangan dari PRD:** PRD mendefinisikan `@Index(unique: true) int garminActivityId` dengan nilai `0` untuk impor manual tanpa ID, yang akan menyebabkan kegagalan constraint unik pada impor manual kedua.
- **Keputusan:**
  1. `garminActivityId` dibuat **nullable (`int?`)** dengan *unique partial index* (`WHERE garmin_activity_id IS NOT NULL`).
  2. Deduplikasi aktivitas impor manual mengandalkan **`fitFileHash` (SHA-256)**; deduplikasi aktivitas sinkronisasi Garmin mengandalkan `garminActivityId` + perbandingan `fitFileHash` untuk mendeteksi pembaruan.

---

## ADR-003 — Kebijakan Sinkronisasi: Mendukung Data Seluler, Tanpa Wajib Charging, & Threshold App-Open Responsif

- **Status:** Disetujui
- **Referensi PRD:** §2.3 (App open trigger), `M1-10`, `NFR-03`
- **Penyimpangan dari PRD:**
  1. `M1-10` & `NFR-03` membatasi *Background Sync* hanya saat **Wi-Fi + charging**.
  2. §2.3 membatasi *auto-sync* saat aplikasi dibuka hanya jika `lastSync > 6 jam`.
- **Keputusan:**
  1. **Background Sync (`WorkManager` / `BGTaskScheduler`):** Default mengizinkan sinkronisasi pada **koneksi internet apa pun (Wi-Fi maupun data seluler)** dan **tidak mensyaratkan perangkat sedang di-charge** (`NetworkType.connected`, `requiresCharging: false`). Pengguna tetap diberi opsi di *Settings* jika ingin membatasi ke Wi-Fi saja.
  2. **App-Open / Resume Auto-Sync:** Menurunkan threshold dari `6 jam` menjadi **`5–15 menit`** (dengan *debounce* 60 detik) agar aktivitas yang baru selesai disinkronkan oleh jam ke Garmin Connect segera masuk saat FitTrace dibuka.
  3. Catatan OS: Interval minimum periodik `WorkManager` Android tetap mengikuti batasan OS (≥ 15 menit), dan FitTrace tetap mengambil data dari akun Garmin Connect pengguna (bukan koneksi Bluetooth langsung ke jam).

---

## ADR-004 — Isolasi `metrics_engine` (Pure Dart), Fallback HRmax, & Retensi `.fit.gz` Bertahap

- **Status:** Disetujui
- **Referensi PRD:** `M1-06`, `M2-03`–`M2-07`, `M5-01`, `NFR-05`
- **Keputusan:**
  1. `metrics_engine` ditempatkan sebagai package Dart murni terpisah (`packages/metrics_engine`) tanpa ketergantungan Flutter, dengan seluruh kalkulasi internal memakai satuan **meter, detik, m/s, dan UTC**.
  2. Fallback `HRmax` (`M2-06`): `hrMaxManual` → `220 - umur (birthDate)` → default **`190 bpm`** (ditandai sebagai estimasi di UI bila profil belum diisi).
  3. Konsistensi `M1-06` vs `M5-01`: File *temp* unduhan segera dihapus setelah commit DB sukses, sedangkan arsip terkompresi `.fit.gz` dipertahankan di penyimpanan internal selama 30 hari untuk ekspor bit-identical; *FIT encoder/regenerator* untuk aktivitas lebih lama dari 30 hari diimplementasikan di Phase 5.

---

## ADR-005 — Native MethodChannel Tipis untuk Instagram Story Sharing

- **Status:** Disetujui (Target Implementasi Phase 4)
- **Referensi PRD:** `M4-01`–`M4-07`
- **Keputusan:**
  1. Menggunakan *custom `MethodChannel`* (`com.fittrace.app/story_share`) berbasis Kotlin (Android) dan Swift (iOS) dibandingkan plugin pihak ketiga lama, dengan `FileProvider` dan `<queries>` untuk `com.instagram.android`.
  2. *Template A (Route Glow)* dan *Template C (Minimalist)* mengekspor aset latar penuh `1080×1920`, sedangkan *Template B (Photo Overlay)* menggunakan kombinasi latar foto + stiker RGBA transparan. Fallback *Simpan ke Galeri* disediakan sejak awal.

