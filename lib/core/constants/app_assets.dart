/// Semua path gambar dan icon dikumpulkan di sini.
/// Jangan menulis 'assets/...' langsung di widget; pakai konstanta ini.
class AppAssets {
  AppAssets._();

  // ===== Gambar =====
  static const String _images = 'assets/images';
  static const String logo = '$_images/logo_sadaqo.png'; // logo + teks
  static const String logoEmblem = '$_images/logo_sadaqo_emblem.png'; // tanpa teks

  /// Foto program. Taruh file di assets/images/programs/, lalu isi
  /// field imageAsset di mock datasource dengan path ini.
  /// Contoh: '${AppAssets.programs}/masjid_al_falah.jpg'
  static const String programs = '$_images/programs';

  // ===== Icon =====
  static const String _icons = 'assets/icons';
  static const String appIcon = '$_icons/app_icon.png'; // sumber launcher icon
}
