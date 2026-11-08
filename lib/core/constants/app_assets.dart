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
  static String news(String file) => '$_images/news/$file';

  static const String zakatFitrah = '$_images/zakat/zakat_fitrah.jpg';
  static const String zakatMaal = '$_images/zakat/zakat_maal.jpg';

  // ===== Avatar profil (nama file: pria / wanita) =====
  static const String _avatar = '$_images/avatar';
  static const List<String> avatarsMale = [
    '$_avatar/01_pria_kacamata_hoodie.png',
    '$_avatar/03_pria_jaket_hijau.png',
    '$_avatar/05_pria_songkok.png',
    '$_avatar/07_pria_ikat_kepala.png',
  ];
  static const List<String> avatarsFemale = [
    '$_avatar/02_wanita_rambut_panjang.png',
    '$_avatar/04_wanita_rambut_pendek.png',
    '$_avatar/06_wanita_hijab_krem.png',
    '$_avatar/08_wanita_cadar_hijau.png',
  ];
  static const List<String> avatars = [...avatarsMale, ...avatarsFemale];
  
  // ===== Icon =====
  static const String _icons = 'assets/icons';
  static const String appIcon = '$_icons/app_icon.png';

  // Ikon kategori
  static const String iconMasjid = '$_icons/ikon_masjid.png';
  static const String iconSosial = '$_icons/ikon_sosial.png';
  static const String iconZakat = '$_icons/ikon_zakat.png';
  static const String iconDuafa = '$_icons/ikon_duafa.png';
  static const String iconQurban = '$_icons/ikon_qurban.png';

  // Ikon navigasi bawah
  static const String iconBeranda = '$_icons/ikon_beranda.png';
  static const String iconProgram = '$_icons/ikon_program.png';
  static const String iconDonasi = '$_icons/ikon_donasi.png';
  static const String iconRiwayat = '$_icons/ikon_riwayat.png';
  static const String iconProfil = '$_icons/ikon_profil.png';
    static const String iconKomunitas = '$_icons/ikon_komunitas.png';
}