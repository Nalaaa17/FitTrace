# Store Release Prep Checklist — FitTrace v1.0.0 (`com.fittrace.app`)

## 1. Identitas & Ikon Monokrom
- **Package / Bundle ID:** `com.fittrace.app`
- **Adaptive Launcher Icon (Android):** Monokrom hitam pekat (`#0A0A0A`) + glyph rute putih (`#FFFFFF`) di `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` (+ `<monochrome>` layer untuk Android 13+ Themed Icons).
- **iOS AppIcon:** Siapkan PNG monokrom `1024×1024` tanpa kanal alfa dari `ic_launcher_foreground.xml` di `ios/Runner/Assets.xcassets/AppIcon.appiconset/` sebelum archive App Store.

## 2. Daftar Screenshot Monokrom Wajib (1080×2400 / 9:16 & 9:19.5)
1. **Activity Feed (Dark Mode):** Kartu metrik mingguan/bulanan + daftar lari dengan thumbnail rute `200×120` dan badge `SYNCED` / `LOCAL_ONLY`.
2. **Activity Detail & Peta Monokrom:** Hero numbers `KM / PACE / MOVING TIME` + peta dark-desaturated dengan gradient pace polyline.
3. **Interactive Synced Chart & Splits:** Grafik triple-metric (Pace, Elevasi, HR) + tabel splits dengan aksen `BEST` split & bar HR Zone 1–5.
4. **Story Card Editor (3 Template):** Tangkapan *Route Glow*, *Photo Overlay*, dan *Minimalist Metrics* pada kanvas 9:16 `1080×1920`.
5. **Local-First Backup & Settings:** Pengaturan HRmax/zona, toggle seluler/baterai ADR-003, dan Backup/Restore `.ZIP`.

## 3. Google Play Data Safety & Apple App Privacy
- **Data collected by developer:** **None** (Tidak ada data yang dikirim ke server pengembang).
- **Data stored on device only:** Lokasi GPS latihan, metrik kebugaran (pace, elevasi, HR), foto latar Story pilihan pengguna, tanggal lahir opsional.
- **Permissions declared & optional:**
  - `INTERNET` / `ACCESS_NETWORK_STATE`: Opsional untuk Garmin sync & OSM tile.
  - `ACCESS_FINE_LOCATION` / `POST_NOTIFICATIONS` / `READ_EXTERNAL_STORAGE` (maxSdk 32): Semuanya non-blocking saat onboarding.
- **Privacy Policy URL:** Publikasikan [PRIVACY_POLICY.md](PRIVACY_POLICY.md) pada halaman web/GitHub Pages statis saat submit rilis store.

