# FitTrace — Local-First Running Analytics

FitTrace adalah aplikasi analitik lari *local-first* dan *offline-first* berbasis Flutter. Seluruh aktivitas `.FIT`, metrik fisiologis, rute GPS, pelacakan keausan sepatu, hingga generasi kartu Story Instagram disimpan dan diproses langsung di perangkat pengguna tanpa server backend atau telemetri pihak ketiga.

---

## Fitur Utama

- **Feed Aktivitas & Impor `.FIT`:** Impor manual berkas `.FIT` (termasuk dari *Android Share Intent*) dengan filter pencarian ber-debounce dan paginasi SQLite.
- **Sinkronisasi Garmin Connect:** Dukungan login Garmin WebView & Personal API Key (`GCDC_...`) dengan penyimpanan cookie/token terenkripsi di Android Keystore / iOS Keychain serta *background sync* terjadwal.
- **Analitik Mendalam (`metrics_engine`):**
  - Deteksi interval otomatis (*sprint–recovery*).
  - Perhitungan Best Efforts (1K, 5K, 10K, Half Marathon, Marathon) & estimasi VDOT.
  - Grafik tren mingguan (jarak, pace, HR) & *consistency heatmap*.
  - Peta rute OpenStreetMap dengan LRU *disk tile cache*.
- **Target Mingguan & Pelacakan Sepatu:** Pantau target kilometer mingguan dan keausan sol sepatu (peringatan pada 500–800 km).
- **Story Share 1080×1920:** Generator kartu statistik transparan/foto untuk Instagram Stories dengan preset kustom.
- **Backup & Ekspor Penuh:** Ekspor `.FIT`, ringkasan `.CSV`, serta cadangan & pemulihan `.ZIP` lokal lengkap.

---

## Struktur Proyek

```text
lib/
├── core/
│   ├── config/          # Metadata versi tunggal (AppInfo)
│   ├── database/        # Drift SQLite schema, migrasi, DAO & model inti
│   ├── error/           # Tipe kegagalan aplikasi (AppFailure)
│   ├── logging/         # AppLogger dengan credential scrubbing & diagnostic buffer
│   ├── routing/         # AppRouter & deep linking (`fittrace://`)
│   ├── theme/           # FitTraceColors (Dark & Light) & AppTypography
│   └── utils/           # UnitFormatter (Metric / Imperial)
├── features/            # Fitur modular (feed, activity_detail, stats, shoes, weekly_target, intervals, garmin_sync, story_share, backup, settings, onboarding)
└── l10n/                # File lokalisasi (.arb) Bahasa Indonesia & Inggris

packages/
└── metrics_engine/      # Paket komputasi murni untuk parsing/metrik lari
```

---

## Persiapan & Pengembangan

### 1. Instalasi Dependensi & Code Generation
```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

### 2. Analisis Kode & Unit Test
```bash
flutter analyze
flutter test
```

### 3. Build Release APK (Android Signing)
Konfigurasi release menuntut berkas `android/key.properties` (jangan di-commit ke Git):
```properties
storePassword=<password-keystore>
keyPassword=<password-key>
keyAlias=<alias>
storeFile=<path-ke-file.jks>
```
Lalu jalankan:
```bash
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

---

## Dokumentasi Tambahan
- [Architecture Decision Records](docs/ADR.md)
- [Fase Pengembangan](docs/PHASES.md)
- [Kebijakan Privasi](docs/PRIVACY_POLICY.md)
