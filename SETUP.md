# Setup Tahap 1 (Flutter)

1. Buat project:        flutter create sadaqo
2. Hapus test bawaan:   hapus file test/widget_test.dart (merujuk ke MyApp lama)
3. Tambah dependency:   flutter pub add flutter_bloc equatable get_it dartz dio intl
4. Salin ke project:    folder lib/  (ganti)  dan folder assets/  (baru, sejajar lib/)
5. Daftarkan assets di pubspec.yaml, di bawah `flutter:` (perhatikan indentasi 2 spasi):

       flutter:
         uses-material-design: true
         assets:
           - assets/images/
           - assets/icons/
           - assets/illustrations/

6. flutter pub get, lalu flutter run

## Opsional: ganti icon launcher dengan logo SADAQO
   flutter pub add dev:flutter_launcher_icons
   Tambahkan di pubspec.yaml (sejajar `flutter:`, bukan di dalamnya):

       flutter_launcher_icons:
         android: true
         ios: false
         image_path: "assets/icons/app_icon.png"

   Lalu jalankan: dart run flutter_launcher_icons
