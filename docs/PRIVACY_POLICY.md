# Kebijakan Privasi — FitTrace (100% Local-Only)

**Tanggal Berlaku:** 12 November 2026  
**Pengembang:** FitTrace (`com.fittrace.app`)

FitTrace adalah aplikasi analisis lari berbasis **local-first** tanpa backend server pengembang. Privasi pelari adalah prinsip desain inti kami.

---

## 1. Data yang Diproses di Perangkat
Seluruh data aktivitas lari (koordinat GPS, elevasi, kecepatan/pace, detak jantung, cadensi, split per kilometer, tanggal lahir/HRmax opsional, serta arsip `.FIT`) disimpan **exclusively di penyimpanan lokal perangkat Anda** (SQLite Drift & direktori internal terisolasi).

- **Tidak ada server pengembang:** FitTrace tidak mengoperasikan REST API, database cloud, atau akun pengembang.
- **Tidak ada SDK analitik atau iklan:** Tidak ada pelacakan penggunaan, fingerprinting perangkat, atau crash telemetry yang memuat data aktivitas.

## 2. Kredensial Garmin Connect (Opsional)
Jika Anda memilih menghubungkan akun Garmin Connect:
- Autentikasi berlangsung langsung antara perangkat Anda dan domain resmi `garmin.com` melalui HTTPS ketat.
- Cookie sesi hanya disimpan terenkripsi di **Android Keystore / iOS Keychain** (`flutter_secure_storage`).
- Cookie/token **tidak pernah** dicatat ke log aplikasi, **tidak pernah** disimpan ke database SQLite, dan **tidak pernah** disertakan dalam file ekspor maupun arsip backup `.ZIP`.
- Anda dapat memutuskan akun dan menghapus sesi kapan saja lewat menu *Pengaturan*.

## 3. Peta & Berbagi ke Instagram Stories
- **Peta OpenStreetMap:** Hanya mengunduh tile peta publik (HTTPS) saat melihat rute outdoor dan menyimpannya sementara di cache disk lokal (batas LRU 100 MB).
- **Instagram Stories:** Kartu statistik `1080×1920` dirender lokal di perangkat dan hanya dibagikan bila Anda menekan **Bagikan IG** atau **Simpan ke Galeri**. File draft PNG sementara di cache dibersihkan otomatis setelah **24 jam**.

## 4. Hak Pengguna & Penghapusan Data
Karena 100% data berada di perangkat Anda, Anda memegang kendali penuh untuk mengekspor ulang `.FIT`, membuat cadangan `.ZIP`, menghapus aktivitas tertentu, atau menjalankan **Factory Reset Lokal** di *Pengaturan* untuk menghapus seluruh data secara permanen.

---

# Privacy Policy (English Summary)

FitTrace (`com.fittrace.app`) operates **100% locally** with zero developer servers, zero cloud accounts, and zero advertising or behavioral analytics SDKs. Optional Garmin Connect session cookies are encrypted strictly inside Android Keystore / iOS Keychain and excluded from all logs and `.ZIP` backups. Data leaves the device only when you explicitly initiate a sync with Garmin Connect, load OpenStreetMap tiles, export a file, or share a Story card to Instagram.

