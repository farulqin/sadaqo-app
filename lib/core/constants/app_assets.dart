/// Semua path gambar dan icon dikumpulkan di sini.
/// Jangan menulis 'assets/...' langsung di widget; pakai konstanta ini
/// supaya kalau file dipindah atau diganti, cukup ubah satu tempat.
class AppAssets {
  AppAssets._();

  // ===== Gambar =====
  static const String _images = 'assets/images';
  static const String logo = '$_images/logo_sadaqo.png'; // logo + teks
  static const String logoEmblem = '$_images/logo_sadaqo_emblem.png'; // tanpa teks

  // ===== Icon =====
  static const String _icons = 'assets/icons';
  static const String appIcon = '$_icons/app_icon.png'; // sumber launcher icon

  // ===== Ilustrasi (empty state, onboarding, dll) =====
  // static const String _illustrations = 'assets/illustrations';
}
