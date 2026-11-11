import 'package:flutter/foundation.dart';
import 'package:sadaqo/core/constants/app_assets.dart';

class AdminUser {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.joinedAt,
    this.phone,
    this.avatarAsset,
    this.isDemo = false,
    this.isManager = false,
  });

  final String id;
  final String name;
  final String email;
  final DateTime joinedAt;
  final String? phone;
  final String? avatarAsset;

  /// true = pengguna contoh (seed), false = pengguna yang benar-benar masuk/daftar.
  final bool isDemo;

  /// true = akun Pengelola Kampanye (tim teknis SADAQO).
  final bool isManager;

  AdminUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarAsset,
    bool clearAvatar = false,
  }) =>
      AdminUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        joinedAt: joinedAt,
        phone: phone ?? this.phone,
        avatarAsset: clearAvatar ? null : (avatarAsset ?? this.avatarAsset),
        isDemo: isDemo,
        isManager: isManager,
      );
}

/// Daftar pengguna untuk dashboard admin.
/// - Pengguna contoh (seed) agar halaman tidak kosong; id 'seed-1..4' sama dengan
///   pengguna contoh di Komunitas, jadi banned dari admin ikut berlaku di sana.
/// - Pengguna asli otomatis tercatat saat masuk/daftar lewat [registerFromAuth].
class AdminUserStore extends ChangeNotifier {
  AdminUserStore() : _items = _seed();

  List<AdminUser> _items;
  int _counter = 1;

  List<AdminUser> get all => List.unmodifiable(_items);
  int get count => _items.length;

  AdminUser? byId(String id) {
    for (final u in _items) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// Dipanggil AuthMockDataSource setiap ada pengguna masuk/daftar.
  void registerFromAuth({
    required String id,
    required String name,
    required String email,
    String? phone,
    bool isManager = false,
  }) {
    final i = _items.indexWhere((u) => u.id == id);
    if (i >= 0) {
      _items = List.of(_items)
        ..[i] = _items[i].copyWith(name: name, email: email, phone: phone);
    } else {
      _items = [
        AdminUser(
          id: id,
          name: name,
          email: email,
          phone: phone,
          joinedAt: DateTime.now(),
          isManager: isManager,
        ),
        ..._items,
      ];
    }
    notifyListeners();
  }

  void add({
    required String name,
    required String email,
    String? phone,
    String? avatarAsset,
  }) {
    _items = [
      AdminUser(
        id: 'adm-u${_counter++}',
        name: name,
        email: email,
        phone: phone,
        avatarAsset: avatarAsset,
        joinedAt: DateTime.now(),
      ),
      ..._items,
    ];
    notifyListeners();
  }

  void update(AdminUser user) {
    final i = _items.indexWhere((u) => u.id == user.id);
    if (i < 0) return;
    _items = List.of(_items)..[i] = user;
    notifyListeners();
  }

  void remove(String id) {
    _items = _items.where((u) => u.id != id).toList();
    notifyListeners();
  }

  static List<AdminUser> _seed() {
    final now = DateTime.now();
    AdminUser u(String id, String name, String email, int daysAgo,
            {String? avatar, String? phone}) =>
        AdminUser(
          id: id,
          name: name,
          email: email,
          phone: phone,
          avatarAsset: avatar,
          joinedAt: now.subtract(Duration(days: daysAgo)),
          isDemo: true,
        );
    return [
      u('seed-1', 'Siti Rahma', 'siti.rahma@example.com', 210,
          avatar: AppAssets.avatarsFemale[2], phone: '0812-3000-1101'),
      u('seed-2', 'Ahmad Fauzi', 'ahmad.fauzi@example.com', 185,
          avatar: AppAssets.avatarsMale[2], phone: '0813-3000-1102'),
      u('seed-3', 'Hamba Allah', 'anonim.satu@example.com', 160),
      u('seed-4', 'Nur Aini', 'nur.aini@example.com', 140,
          avatar: AppAssets.avatarsFemale[1]),
      u('seed-5', 'Rizki Ramadhan', 'rizki.r@example.com', 120,
          avatar: AppAssets.avatarsMale[0]),
      u('seed-6', 'Dewi Lestari', 'dewi.lestari@example.com', 98,
          avatar: AppAssets.avatarsFemale[0]),
      u('seed-7', 'Budi Santoso', 'budi.santoso@example.com', 75,
          avatar: AppAssets.avatarsMale[1]),
      u('seed-8', 'Aisyah Putri', 'aisyah.putri@example.com', 60,
          avatar: AppAssets.avatarsFemale[3]),
      u('seed-9', 'Fajar Nugroho', 'fajar.n@example.com', 44,
          avatar: AppAssets.avatarsMale[3]),
      u('seed-10', 'Laila Hidayati', 'laila.h@example.com', 30),
      u('seed-11', 'Yusuf Hakim', 'yusuf.hakim@example.com', 17),
      u('seed-12', 'Maya Anggraini', 'maya.a@example.com', 9),
    ];
  }
}
