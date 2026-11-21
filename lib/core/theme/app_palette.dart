import 'package:flutter/material.dart';

/// Tiga tampilan yang bisa dipilih donatur.
enum AppThemeMode {
  light('Terang'),
  dark('Gelap'),
  glass('Liquid Glass');

  const AppThemeMode(this.label);
  final String label;
}

/// Kumpulan warna satu tampilan. `AppColors` membaca palet yang sedang aktif.
class AppPalette {
  const AppPalette({
    required this.mode,
    required this.background,
    required this.surface,
    required this.popup,
    required this.appBar,
    required this.sandBeige,
    required this.textDark,
    required this.textMuted,
    required this.success,
    required this.successSoft,
    required this.error,
    required this.brandInk,
    required this.pill,
    required this.tintCream,
    required this.tintLime,
    required this.tintGold,
    required this.tintRose,
    required this.navTop,
    required this.navBottom,
    required this.navBorder,
    required this.navShadow,
    required this.shimmerBase,
    required this.shimmerHighlight,
  });

  final AppThemeMode mode;

  /// Latar halaman. Pada Liquid Glass transparan (gradien tampil di belakang).
  final Color background;

  /// Latar kartu dan panel.
  final Color surface;

  /// Latar dialog, lembar bawah, dan menu (selalu cukup pekat agar terbaca).
  final Color popup;
  final Color appBar;

  /// Latar chip, jalur progress, dan garis tepi.
  final Color sandBeige;
  final Color textDark;
  final Color textMuted;
  final Color success;
  final Color successSoft;
  final Color error;

  /// Warna merek untuk teks dan ikon di atas permukaan (hijau tua di tema
  /// Terang, lime di tema Gelap dan Liquid Glass).
  final Color brandInk;

  /// Latar kapsul/label kecil di dalam kartu.
  final Color pill;
  final Color tintCream;
  final Color tintLime;
  final Color tintGold;
  final Color tintRose;

  final Color navTop;
  final Color navBottom;
  final Color navBorder;
  final Color navShadow;

  final Color shimmerBase;
  final Color shimmerHighlight;

  /// Hanya tema Gelap. Liquid Glass tergolong tema terang.
  bool get isDark => mode == AppThemeMode.dark;
  bool get isGlass => mode == AppThemeMode.glass;

  /// Palet yang sedang dipakai seluruh aplikasi.
  static AppPalette current = light;

  static AppPalette of(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return light;
      case AppThemeMode.dark:
        return dark;
      case AppThemeMode.glass:
        return glass;
    }
  }

  // ---- Terang: sama persis dengan tampilan sebelumnya ----
  static const light = AppPalette(
    mode: AppThemeMode.light,
    background: Color(0xFFF8F4EA),
    surface: Color(0xFFFFFFFF),
    popup: Color(0xFFFFFFFF),
    appBar: Color(0xFF1F3D2B),
    sandBeige: Color(0xFFE8DCC4),
    textDark: Color(0xFF1A1A1A),
    textMuted: Color(0xFF6B6B6B),
    success: Color(0xFF3E8E41),
    successSoft: Color(0xFFDDEFC6),
    error: Color(0xFFB3261E),
    brandInk: Color(0xFF1F3D2B),
    pill: Color(0xFFF8F4EA),
    tintCream: Color(0xFFF1EFDD),
    tintLime: Color(0xFFE9F3D2),
    tintGold: Color(0xFFF3EBC8),
    tintRose: Color(0xFFF8DEDB),
    navTop: Color(0xD1FFFFFF),
    navBottom: Color(0x9EFFFFFF),
    navBorder: Color(0xE6FFFFFF),
    navShadow: Color(0x331F3D2B),
    shimmerBase: Color(0xFFE6DFCB),
    shimmerHighlight: Color(0xFFF8F4E8),
  );

  // ---- Gelap: hijau sangat tua ----
  static const dark = AppPalette(
    mode: AppThemeMode.dark,
    background: Color(0xFF0D1913),
    surface: Color(0xFF16251C),
    popup: Color(0xFF1A2C22),
    appBar: Color(0xFF1F3D2B),
    sandBeige: Color(0xFF26392D),
    textDark: Color(0xFFE8F0E6),
    textMuted: Color(0xFF9DB1A3),
    success: Color(0xFF63C36B),
    successSoft: Color(0xFF1F3B27),
    error: Color(0xFFFF8A80),
    brandInk: Color(0xFFA3D65C),
    pill: Color(0xFF1B2D22),
    tintCream: Color(0xFF1C2F23),
    tintLime: Color(0xFF23402B),
    tintGold: Color(0xFF3A3519),
    tintRose: Color(0xFF3C2321),
    navTop: Color(0xCC1B2D23),
    navBottom: Color(0xB314231A),
    navBorder: Color(0x24FFFFFF),
    navShadow: Color(0x66000000),
    shimmerBase: Color(0xFF1E3026),
    shimmerHighlight: Color(0xFF2B4235),
  );

  // ---- Liquid Glass: terang, kaca buram (frosted), teks dan ikon hijau forest ----
  static const glass = AppPalette(
    mode: AppThemeMode.glass,
    background: Color(0x00000000),
    surface: Color(0xB8FFFFFF),
    popup: Color(0xF7F3F8EC),
    appBar: Color(0xE61F3D2B),
    sandBeige: Color(0x331F3D2B),
    textDark: Color(0xFF1F3D2B),
    textMuted: Color(0xFF557263),
    success: Color(0xFF2E7D32),
    successSoft: Color(0x4DA3D65C),
    error: Color(0xFFB3261E),
    brandInk: Color(0xFF1F3D2B),
    pill: Color(0x99FFFFFF),
    tintCream: Color(0x73FFFFFF),
    tintLime: Color(0x47A3D65C),
    tintGold: Color(0x4DF2D37A),
    tintRose: Color(0x40E57373),
    navTop: Color(0xC7FFFFFF),
    navBottom: Color(0x85FFFFFF),
    navBorder: Color(0xE6FFFFFF),
    navShadow: Color(0x2E1F3D2B),
    shimmerBase: Color(0xFFD5E4CA),
    shimmerHighlight: Color(0xFFF3F8EC),
  );
}
