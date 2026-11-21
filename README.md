# SADAQO

**Platform Mobile Penggalangan Dana Komunitas dan Qurban Patungan**
*Berbagi Kebaikan, Menebar Manfaat*

Project akhir UAS Pemrograman Aplikasi Bergerak. Aplikasi Flutter (Android, iOS, dan web) dengan
backend Laravel REST API untuk donasi pada lima kategori program: **Masjid & Mushola**,
**Bantuan Sosial**, **Zakat**, **Kaum Duafa**, dan **Qurban Bersama**.

> Pembayaran pada versi ini adalah **simulasi**. Tidak ada uang sungguhan yang berpindah dan
> tidak ada data kartu yang disimpan. Nama program, berita, dan angka pada data contoh bersifat
> fiktif untuk pengembangan.

## Fitur

### Donatur
| Fitur | Status |
|---|---|
| Splash dengan animasi logo, daftar dan masuk (email, serta Google dan Apple) | Selesai |
| Beranda: total donasi, kategori, berita (carousel otomatis), program baru | Selesai |
| Katalog program dengan filter kategori, pencarian, urutan, dan detail dengan progres dana | Selesai |
| Donasi via QRIS, e-wallet, dan transfer bank (simulasi) dengan 17 logo penyedia | Selesai |
| Qurban patungan: harga per unit, kuota, dan program tertutup otomatis saat penuh | Selesai |
| Zakat: kalkulator, niat, dan pembayaran dengan nominal tetap | Selesai |
| Riwayat donasi, notifikasi, dan program favorit | Selesai |
| Profil: ringkasan, grafik aktivitas, lencana pencapaian, foto profil tersimpan permanen | Selesai |
| Komunitas: post, polling, komentar, agenda, anggota, lencana, dan laporan konten | Selesai |
| Berita: baca isi dan donasi ke program terkait | Selesai |

### Pengelola kampanye
Mengajukan program, memantau donasi masuk, dan menyusun laporan penyaluran dana beserta foto bukti.

### Admin
Dashboard dan statistik, verifikasi program, kelola program, pengguna (peringatan, banned, nonaktif),
transaksi, berita, kategori, tinjauan laporan penyaluran, serta moderasi Komunitas
(Laporan, pantauan **Live** dengan menulis post dan polling, dan agenda).

### Tampilan dan animasi
- **Tiga tema**: Terang, Gelap, dan **Liquid Glass** (terang bergaya kaca). Dapat dipilih dari
  Beranda dan Pengaturan, tersimpan permanen. Admin dan pengelola selalu memakai tema Terang.
- Animasi: efek tekan tombol, hover dan tekan kartu, skeleton shimmer, progress bar terisi bertahap,
  angka naik (count-up), cross-fade pada filter, fade-through pada pergantian tab, navbar kaca
  dengan indikator cair, serta animasi centang dan konfeti saat donasi berhasil.
  Semua animasi mengikuti pengaturan "kurangi animasi" pada perangkat.

### Aturan bisnis penting
- Pendaftaran publik selalu menjadi **donatur**. Program buatan pengelola berstatus *pending* sampai
  disetujui admin.
- Donasi minimal Rp 5.000 (kecuali zakat). Program ditutup otomatis saat target tercapai atau kuota penuh.
- Komunitas: konten disaring otomatis. Pelanggaran ke-1 berupa peringatan, pelanggaran ke-2
  membuat akun dibanned 30 hari.

## Teknologi

| Bagian | Teknologi |
|---|---|
| Aplikasi | Flutter (Dart ^3.13), `flutter_bloc` (Cubit), `get_it`, `dartz`, `dio`, `intl`, `shared_preferences`, `flutter_secure_storage`, `image_picker`, `qr_flutter`, `google_sign_in`, `sign_in_with_apple` |
| Backend | PHP 8.3, Laravel 13, Laravel Sanctum (autentikasi token) |
| Basis data | MySQL (Laragon) atau SQLite, 27 tabel domain |
| Pengujian | PHPUnit (backend) |

Arsitektur aplikasi: *clean architecture* per fitur (`data` / `domain` / `presentation`).
Alur data: `Halaman -> Cubit -> UseCase -> Repository -> DataSource -> REST API`.

## Struktur folder

```
sadaqo-app/
├── lib/
│   ├── core/            konstanta, tema (3 tampilan), jaringan, error, utilitas, widget bersama
│   ├── features/        auth, home, campaign, donation, zakat, news, notification, favorite,
│   │                    profile, report, community_feed, splash
│   │   └── (tiap fitur) data/ domain/ presentation/
│   ├── admin/           panel admin
│   ├── pengelola/       panel pengelola kampanye
│   ├── injection_container.dart
│   └── main.dart
├── assets/              images (termasuk payment/), icons, illustrations
├── backend/             Laravel REST API (migrasi, model, seeder, tes)
├── database/            ERD.md, gambar ERD, dan kumpulan query SQL
└── pubspec.yaml
```

## Cara menjalankan

### 1. Backend (Laravel)

Kebutuhan: PHP 8.3+, Composer, dan MySQL (mis. Laragon) atau SQLite.

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

API berjalan di `http://127.0.0.1:8000/api` (cek dengan `GET /api/ping`).
Untuk MySQL, atur `DB_CONNECTION=mysql` dan `DB_DATABASE=sadaqo` di `.env`, lalu buat database
`sadaqo` terlebih dahulu. Rincian lengkap ada di [`backend/README.md`](backend/README.md).

### 2. Aplikasi Flutter

```bash
flutter pub get
flutter run -d chrome
```

Alamat API dipilih otomatis: `127.0.0.1:8000` untuk web dan desktop, `10.0.2.2:8000` untuk emulator
Android. Untuk perangkat lain atau server berbeda:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

### Akun contoh (dari seeder)

| Peran | Email |
|---|---|
| Admin | `sadaqo.admin@gmail.com` |
| Pengelola | `sadaqo.pengelola@gmail.com` |
| Donatur | `donatur.demo@sadaqo.test` |

Kata sandi dibaca dari `backend/.env` (`SEED_ADMIN_PASSWORD`, `SEED_PENGELOLA_PASSWORD`,
`SEED_DONATUR_PASSWORD`). Bila dikosongkan, kata sandi acak ditampilkan sekali di terminal saat seeding.

## Pengujian

```bash
cd backend
php artisan test
```

Mencakup autentikasi, donasi, persetujuan program, Komunitas, moderasi, dan penyaring konten.

```bash
flutter analyze
```

## Dokumentasi basis data

- [`database/ERD.md`](database/ERD.md): rancangan tabel dan relasi.
- `database/erd/`: gambar ERD (inti dan Komunitas).
- `database/query_sadaqo.sql`: kumpulan query contoh (join, agregasi, subquery).

## Identitas visual

Forest Green `#1F3D2B` (utama), Sand Beige `#E8DCC4` (sekunder), Lime Green `#A3D65C` (aksen).
Tema Gelap memakai hijau sangat tua, dan tema Liquid Glass memakai latar hijau-krem lembut dengan
kartu kaca buram.

## Rencana pengembangan

- Integrasi *payment gateway* sungguhan dengan *webhook* konfirmasi.
- Pembaruan Komunitas real-time dengan WebSocket (Laravel Reverb atau Pusher), menggantikan polling.
- Unggah foto profil ke server (saat ini tersimpan di perangkat).
- Pengujian antarmuka Flutter (*widget* dan *integration test*) dan CI.

## Pengembang

Farid Ulil Yaqin, NIM 24051214176