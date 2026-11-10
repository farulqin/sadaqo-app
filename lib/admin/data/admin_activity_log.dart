import 'package:flutter/foundation.dart';

enum ActivityKind { verified, user, donation, report, community, content }

class AdminActivity {
  const AdminActivity(this.kind, this.text, this.at);

  final ActivityKind kind;
  final String text;
  final DateTime at;
}

/// Catatan tindakan admin (tambah program, verifikasi, banned, dll).
/// Ditampilkan di "Aktivitas Terbaru" bersama donasi, pengguna baru, dan moderasi.
class AdminActivityLog extends ChangeNotifier {
  final List<AdminActivity> _items = [];

  List<AdminActivity> get all => List.unmodifiable(_items);

  void add(ActivityKind kind, String text) {
    _items.insert(0, AdminActivity(kind, text, DateTime.now()));
    if (_items.length > 100) _items.removeRange(100, _items.length);
    notifyListeners();
  }
}
