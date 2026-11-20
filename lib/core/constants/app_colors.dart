import 'package:flutter/material.dart';
import 'package:sadaqo/core/theme/app_palette.dart';

/// Palet warna SADAQO.
///
/// Tiga warna merek bersifat tetap (const) di semua tampilan. Sisanya mengikuti
/// tampilan aktif (Terang, Gelap, atau Liquid Glass) lewat [AppPalette].
class AppColors {
  AppColors._();

  // ---- Tetap di semua tampilan ----
  static const Color forestGreen = Color(0xFF1F3D2B); // primary (latar panel/tombol)
  static const Color limeGreen = Color(0xFFA3D65C); // accent

  /// Teks/ikon di atas latar lime.
  static const Color onLime = Color(0xFF1F3D2B);

  // ---- Mengikuti tampilan aktif ----
  static AppPalette get _p => AppPalette.current;

  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get popup => _p.popup;
  static Color get appBar => _p.appBar;
  static Color get sandBeige => _p.sandBeige; // secondary
  static Color get textDark => _p.textDark;
  static Color get textMuted => _p.textMuted;
  static Color get success => _p.success;
  static Color get successSoft => _p.successSoft;
  static Color get error => _p.error;

  /// Teks/ikon merek di atas permukaan: hijau tua (Terang) atau lime (Gelap, Glass).
  static Color get brandInk => _p.brandInk;

  static Color get tintCream => _p.tintCream;
  static Color get tintLime => _p.tintLime;
  static Color get tintGold => _p.tintGold;
  static Color get tintRose => _p.tintRose;

  static Color get navTop => _p.navTop;
  static Color get navBottom => _p.navBottom;
  static Color get navBorder => _p.navBorder;
  static Color get navShadow => _p.navShadow;
  static Color get shimmerBase => _p.shimmerBase;
  static Color get shimmerHighlight => _p.shimmerHighlight;

  static bool get isDark => _p.isDark;
  static bool get isGlass => _p.isGlass;
}
