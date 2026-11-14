import 'package:flutter/material.dart';

/// Kunci global agar sesi berakhir (401) bisa mengarahkan ke halaman login
/// dari mana saja.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Dipanggil oleh klien jaringan saat server membalas 401 (token tidak valid
/// atau kedaluwarsa). Pengaturannya ada di main.dart.
class SessionGuard {
  SessionGuard._();

  static VoidCallback? onExpired;

  static void notifyExpired() => onExpired?.call();
}