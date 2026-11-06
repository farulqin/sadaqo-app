/// Semua path gambar dan icon dikumpulkan di sini.
/// Jangan menulis 'assets/...' langsung di widget; pakai konstanta ini.
class AppAssets {
  AppAssets._();

  static const String _images = 'assets/images';
  static const String logo = '$_images/logo_sadaqo.png';
  static const String logoEmblem = '$_images/logo_sadaqo_emblem.png';

  // ===== Foto program, satu folder per fitur =====
  static String masjid(String file) => '$_images/masjid_mushola/$file';
  static String sosial(String file) => '$_images/bantuan_sosial/$file';
  static String duafa(String file) => '$_images/kaum_duafa/$file';
  static String qurban(String file) => '$_images/qurban_bersama/$file';

  static const String zakatFitrah = '$_images/zakat/zakat_fitrah.jpg';
  static const String zakatMaal = '$_images/zakat/zakat_maal.jpg';

  // ===== Icon =====
  static const String appIcon = 'assets/icons/app_icon.png';
}