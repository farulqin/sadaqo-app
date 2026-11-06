# SADAQO

**Platform Mobile Penggalangan Dana Komunitas dan Qurban Patungan**
*Berbagi Kebaikan, Menebar Manfaat*

Project akhir UAS Pemrograman Aplikasi Bergerak. Aplikasi Flutter untuk donasi pada
empat kategori: **Masjid & Musala**, **Bantuan Sosial**, **Anak Yatim**, dan **Qurban**.

> Donasi pada versi ini adalah **simulasi**. Tidak ada uang sungguhan yang berpindah
> dan tidak ada data kartu yang disimpan. Nama program, berita, dan angka pada data
> contoh bersifat fiktif untuk pengembangan.

## Fitur

| Fitur | Status |
|---|---|
| Splash dengan animasi logo | Selesai |
| Login (data mock) | Selesai |
| Beranda: ringkasan donasi, kategori, **berita (carousel otomatis)**, program pilihan | Selesai |
| Berita: baca isi (maks. 1000 kata) dan donasi ke program terkait | Selesai |
| Katalog program, filter kategori, detail, progres dana | Selesai |
| Donasi simulasi dan riwayat donasi | Selesai |
| Profil dan keluar | Selesai |
| Backend Laravel REST API + MySQL | Dalam pengerjaan |
| Qurban patungan (kuota), kalkulator zakat, peta, notifikasi | Rencana |

## Teknologi

- Flutter (Dart), state management **flutter_bloc (Cubit)**
- Clean architecture per fitur: `data` / `domain` / `presentation`
- Dependency injection: `get_it`; HTTP: `dio`; penanganan error: `dartz` (Either)
- Backend (repository terpisah): Laravel REST API, MySQL, Laragon

## Struktur folder

```
lib/
├── core/            konstanta, tema, error, utilitas, widget bersama
├── features/
│   ├── auth/  campaign/  donation/  news/  home/  profile/  splash/
│   │   ├── data/          datasource (mock/API), model, implementasi repository
│   │   ├── domain/        entity, kontrak repository, use case
│   │   └── presentation/  cubit, halaman, widget
├── injection_container.dart
└── main.dart
assets/
├── images/ (logo, programs/)   icons/   illustrations/
```

Alur data: `Halaman -> Cubit -> UseCase -> Repository -> DataSource`.
Selama backend belum tersambung, datasource mock dipakai; pergantian ke API asli
cukup dilakukan di `lib/injection_container.dart`.

## Cara menjalankan

1. Pasang Flutter SDK dan Android Studio (emulator).
2. `flutter pub get`
3. Jalankan emulator Android, lalu `flutter run`

Akun demo (mode mock): email apa saja, password minimal 6 karakter.

Untuk terhubung ke backend lokal dari emulator, alamat API adalah
`http://10.0.2.2:8000/api` (lihat `lib/core/constants/api_constants.dart`).

## Identitas visual

Forest Green `#1F3D2B` (utama), Sand Beige `#E8DCC4` (sekunder), Lime Green `#A3D65C` (aksen).

## Pengembang

Farid Ulil Yaqin, NIM 24051214176
