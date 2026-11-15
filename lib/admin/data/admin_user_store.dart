import 'package:flutter/foundation.dart';
import 'package:sadaqo/admin/data/admin_user_api.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/features/campaign/data/datasources/campaign_manage_api.dart';
import 'package:sadaqo/features/community/domain/entities/moderation.dart';

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
    this.isAdmin = false,
    this.strikes = 0,
    this.bannedUntil,
    this.isActive = true,
    this.donationsTotal = 0,
    this.donationsCount = 0,
  });

  final String id;
  final String name;
  final String email;
  final DateTime joinedAt;
  final String? phone;
  final String? avatarAsset;

  /// true = akun contoh (email @example.com dari seeder demo).
  final bool isDemo;

  /// true = akun Pengelola Kampanye (tim teknis SADAQO).
  final bool isManager;
  final bool isAdmin;
  final int strikes;
  final DateTime? bannedUntil;
  final bool isActive;
  final int donationsTotal;
  final int donationsCount;

  ModerationStatus get moderation =>
      ModerationStatus(strikes: strikes, bannedUntil: bannedUntil);

  factory AdminUser.fromJson(Map<String, dynamic> j) {
    final email = (j['email'] ?? '') as String;
    final role = j['role'];
    return AdminUser(
      id: '${j['id']}',
      name: (j['name'] ?? '') as String,
      email: email,
      joinedAt: DateTime.tryParse('${j['joined_at']}')?.toLocal() ?? DateTime.now(),
      phone: j['phone'] as String?,
      avatarAsset: j['avatar'] as String?,
      isDemo: email.toLowerCase().endsWith('@example.com'),
      isManager: role == 'pengelola',
      isAdmin: role == 'admin',
      strikes: (j['strikes'] as num?)?.toInt() ?? 0,
      bannedUntil: j['banned_until'] is String
          ? DateTime.tryParse(j['banned_until'] as String)?.toLocal()
          : null,
      isActive: j['is_active'] != false,
      donationsTotal: (j['donations_total'] as num?)?.toInt() ?? 0,
      donationsCount: (j['donations_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Daftar pengguna untuk dashboard admin, bersumber dari server (tabel users).
class AdminUserStore extends ChangeNotifier {
  AdminUserStore(this._api, this._assets);

  final AdminUserApi _api;
  final CampaignManageApi _assets;

  List<AdminUser> _items = const [];
  bool _loading = false;
  String? _error;

  List<AdminUser> get all => List.unmodifiable(_items);
  int get count => _items.length;
  bool get loading => _loading;
  String? get error => _error;

  AdminUser? byId(String id) {
    for (final u in _items) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// Dipertahankan agar kode lama tetap kompatibel. Daftar pengguna sekarang
  /// berasal dari server, jadi pencatatan lokal tidak diperlukan lagi.
  void registerFromAuth({
    required String id,
    required String name,
    required String email,
    String? phone,
    bool isManager = false,
  }) {}

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await _api.list();
      _items = rows.map(AdminUser.fromJson).toList();
    } on ServerException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> add({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? avatarAsset,
  }) async {
    final avatarId = await _assets.resolveAssetId(avatarAsset, null);
    await _api.create({
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'avatar_asset_id': ?avatarId,
    });
    await load();
  }

  Future<void> update(
    String id, {
    required String name,
    required String email,
    String? phone,
    String? avatarAsset,
    required bool avatarChanged,
  }) async {
    final body = <String, dynamic>{'name': name, 'email': email, 'phone': phone};
    if (avatarChanged) {
      body['avatar_asset_id'] =
          avatarAsset == null ? null : await _assets.resolveAssetId(avatarAsset, null);
    }
    await _api.update(id, body);
    await load();
  }

  Future<void> setActive(String id, bool active) async {
    await _api.update(id, {'is_active': active});
    await load();
  }

  Future<void> remove(String id) async {
    await _api.delete(id);
    await load();
  }

  Future<void> warn(String id, String note) async {
    await _api.warn(id, note);
    await load();
  }

  Future<void> ban(String id, {int? days, String? reason}) async {
    await _api.ban(id, days: days, reason: reason);
    await load();
  }

  Future<void> lift(String id) async {
    await _api.lift(id);
    await load();
  }
}