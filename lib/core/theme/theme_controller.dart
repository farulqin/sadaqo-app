import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sadaqo/core/theme/app_palette.dart';

/// Mengatur tampilan aktif. Pilihan donatur disimpan permanen.
/// Admin dan pengelola selalu memakai tampilan Terang (dikunci), tanpa
/// mengubah pilihan yang tersimpan.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const _key = 'app_theme_mode';

  AppThemeMode _selected = AppThemeMode.light;
  bool _lockedLight = false;

  /// Pilihan pengguna.
  AppThemeMode get selected => _selected;

  /// Tampilan yang benar-benar dipakai saat ini.
  AppThemeMode get effective => _lockedLight ? AppThemeMode.light : _selected;

  /// Dipasang oleh ThemeScope: mengambil tangkapan layar agar perpindahan
  /// tampilan bisa dibuat memudar halus.
  Future<void> Function()? beforeChange;

  Future<void> load() async {
    try {
      final name = (await SharedPreferences.getInstance()).getString(_key);
      for (final m in AppThemeMode.values) {
        if (m.name == name) _selected = m;
      }
    } catch (_) {}
    AppPalette.current = AppPalette.of(effective);
  }

  Future<void> select(AppThemeMode mode) async {
    if (mode == _selected) return;
    await _apply(() => _selected = mode, animated: true);
    try {
      await (await SharedPreferences.getInstance()).setString(_key, mode.name);
    } catch (_) {}
  }

  /// Dipanggil saat akun admin/pengelola masuk atau keluar.
  void setLockedLight(bool value) {
    if (value == _lockedLight) return;
    _apply(() => _lockedLight = value, animated: false);
  }

  Future<void> _apply(VoidCallback change, {required bool animated}) async {
    if (animated) {
      try {
        await beforeChange?.call();
      } catch (_) {}
    }
    final before = effective;
    change();
    if (effective == before) return;
    AppPalette.current = AppPalette.of(effective);
    notifyListeners();
  }
}
