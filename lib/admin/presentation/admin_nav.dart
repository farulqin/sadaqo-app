import 'package:flutter/material.dart';

enum AdminPage {
  dashboard('Dashboard', Icons.home_rounded),
  programs('Kelola Program', Icons.campaign_rounded),
  verification('Verifikasi Kampanye', Icons.verified_user_rounded),
  reports('Pemeriksaan Laporan', Icons.fact_check_rounded),
  users('Kelola Pengguna', Icons.people_alt_rounded),
  community('Komunitas', Icons.forum_rounded),
  statistics('Statistik Donasi', Icons.insights_rounded),
  transactions('Transaksi Donasi', Icons.receipt_long_rounded),
  news('Berita', Icons.newspaper_rounded),
  categories('Kategori & Media', Icons.grid_view_rounded),
  settings('Pengaturan', Icons.settings_rounded),
  about('Tentang SADAQO', Icons.info_outline_rounded);

  const AdminPage(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Mengatur halaman yang sedang tampil di dashboard admin.
/// [query] dipakai pencarian global agar halaman tujuan langsung terfilter.
class AdminNav extends ChangeNotifier {
  AdminPage _page = AdminPage.dashboard;
  String? _query;
  bool _create = false;
  int _nonce = 0;

  AdminPage get page => _page;

  /// Berubah setiap pindah halaman, dipakai sebagai kunci agar halaman dibangun ulang.
  int get nonce => _nonce;

  /// [create] = true membuka formulir "tambah" di halaman tujuan (jika ada).
  void go(AdminPage page, {String? query, bool create = false}) {
    _page = page;
    _query = query;
    _create = create;
    _nonce++;
    notifyListeners();
  }

  /// Dibaca sekali oleh halaman tujuan.
  String? takeQuery() {
    final q = _query;
    _query = null;
    return q;
  }

  bool takeCreate() {
    final c = _create;
    _create = false;
    return c;
  }
}
