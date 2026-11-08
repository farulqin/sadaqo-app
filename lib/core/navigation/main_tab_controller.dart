import 'package:flutter/foundation.dart';

/// Menyimpan tab aktif di MainShell. Dipakai agar halaman lain bisa berpindah
/// tab (contoh: setelah donasi berhasil, langsung ke tab Riwayat).
class MainTabController {
  static const int home = 0;
  static const int programs = 1;
  static const int donate = 2;
  static const int history = 3;
  static const int profile = 4;

  final ValueNotifier<int> index = ValueNotifier<int>(home);
}