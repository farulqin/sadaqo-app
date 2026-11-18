# SADAQO: Backend API

REST API untuk aplikasi donasi SADAQO (Flutter). Dibangun dengan **Laravel 13**, **PHP 8.3**, dan **Laravel Sanctum** (autentikasi token).

## Fitur

- Autentikasi: daftar, masuk, keluar, profil, masuk dengan Google/Apple
- Tiga peran: **donatur**, **pengelola kampanye**, **admin**
- Program donasi (masjid, sosial, zakat, kaum duafa, qurban) dengan alur pengajuan, persetujuan admin, dan penutupan otomatis saat target tercapai
- Donasi (pembayaran masih simulasi), riwayat, notifikasi, favorit
- Berita dan laporan penyaluran dana oleh pengelola
- Komunitas: post, polling, komentar, agenda, laporan pengguna
- Moderasi: filter konten, peringatan, banned otomatis, tinjauan laporan, tindakan admin

## Kebutuhan

- PHP 8.3 atau lebih baru (ekstensi `pdo_sqlite` atau `pdo_mysql`)
- Composer
- Database SQLite (bawaan) atau MySQL (Laragon)

## Instalasi

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

API berjalan di `http://127.0.0.1:8000/api`. Cek dengan `GET /api/ping`.

Untuk MySQL (Laragon), ubah di `.env`:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=sadaqo
DB_USERNAME=root
DB_PASSWORD=
```

lalu buat database `sadaqo` dan jalankan `php artisan migrate --seed`.

## Akun contoh (seeder)

| Peran | Email |
|-------|-------|
| Admin | `sadaqo.admin@gmail.com` |
| Pengelola | `sadaqo.pengelola@gmail.com` |
| Donatur | `donatur.demo@sadaqo.test` |

Password dibaca dari `.env` (`SEED_ADMIN_PASSWORD`, `SEED_PENGELOLA_PASSWORD`, `SEED_DONATUR_PASSWORD`). Jika dikosongkan, password acak dibuat dan ditampilkan **sekali** di terminal saat seeding.

## Ringkasan endpoint

Semua berawalan `/api`. Rute terlindungi memakai header `Authorization: Bearer <token>`.

| Kelompok | Contoh endpoint | Akses |
|----------|-----------------|-------|
| Publik | `POST /register`, `POST /login`, `GET /campaigns`, `GET /news`, `GET /categories` | Siapa saja |
| Pengguna | `GET /me`, `POST /donations`, `GET /donations`, `GET /notifications`, `POST /favorites/{id}` | Login |
| Komunitas | `GET/POST /community/posts`, `POST /community/polls/{id}/vote`, `POST /community/posts/{id}/comments` | Login (anggota, tidak banned) |
| Pengelola | `POST /campaigns`, `POST /reports` | Pengelola, admin |
| Admin | `PATCH /campaigns/{id}/review`, `GET /admin/users`, `POST /admin/users/{id}/warn`, `/ban`, `/lift`, `PATCH /admin/community/reports/{id}` | Admin |

Daftar lengkap ada di `routes/api.php`.

## Aturan moderasi Komunitas

- Konten disaring otomatis (`App\Support\ContentFilter`): hoaks, ujaran kebencian, penipuan, pornografi, penistaan agama, kata kasar.
- Pelanggaran ke-1 berupa peringatan. Pelanggaran ke-2 membuat akun **dibanned 30 hari** (`CommunityGuard`).
- Admin dapat memberi peringatan, banned dengan lama tertentu, dan mencabut banned.

## Pengujian

```bash
php artisan test
```

Tes memakai SQLite in-memory dan mencakup autentikasi, donasi, persetujuan program, Komunitas, dan moderasi (`tests/Feature`, `tests/Unit`).

## Struktur singkat

```
app/Http/Controllers/Api   Controller REST
app/Http/Middleware        RoleMiddleware (pembatas peran)
app/Models                 Model Eloquent
app/Support                CommunityGuard, ContentFilter, Notifier, dsb.
database/migrations        Skema database
database/seeders           Data awal dan akun contoh
routes/api.php             Seluruh rute API
tests                      Tes PHPUnit
```

## Aplikasi Flutter

Aplikasi mobile/web ada di folder induk (`lib/`). Alamat API dapat diubah saat menjalankan:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```