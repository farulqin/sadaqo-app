import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sadaqo/core/error/exceptions.dart';
import 'package:sadaqo/features/profile/domain/entities/profile_photo.dart';

abstract class ProfileLocalDataSource {
  Future<ProfilePhoto?> getPhoto();
  Future<void> savePhoto(ProfilePhoto? photo);
}

/// Penyimpanan di memori (dipakai untuk pengujian). Foto hilang saat aplikasi ditutup.
class ProfileMemoryDataSource implements ProfileLocalDataSource {
  ProfilePhoto? _photo;

  @override
  Future<ProfilePhoto?> getPhoto() async => _photo;

  @override
  Future<void> savePhoto(ProfilePhoto? photo) async {
    _photo = photo;
  }
}

/// Menyimpan foto profil secara permanen di perangkat (SharedPreferences;
/// di web memakai localStorage). Kuncinya per akun, jadi dua akun di satu
/// perangkat tidak saling menimpa foto.
class ProfilePrefsDataSource implements ProfileLocalDataSource {
  ProfilePrefsDataSource(this._userId);

  /// Mengembalikan id akun yang sedang masuk, atau null bila belum masuk.
  final String? Function() _userId;

  String? get _key {
    final id = _userId();
    return id == null ? null : 'profile_photo_$id';
  }

  @override
  Future<ProfilePhoto?> getPhoto() async {
    final key = _key;
    if (key == null) return null;
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final value = map['value'] as String;
      return map['type'] == 'avatar'
          ? ProfilePhoto.avatar(value)
          : ProfilePhoto.gallery(base64Decode(value));
    } catch (_) {
      return null; // data rusak: anggap belum ada foto
    }
  }

  @override
  Future<void> savePhoto(ProfilePhoto? photo) async {
    final key = _key;
    if (key == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (photo == null) {
        await prefs.remove(key);
        return;
      }
      final map = photo.avatarAsset != null
          ? {'type': 'avatar', 'value': photo.avatarAsset}
          : {'type': 'gallery', 'value': base64Encode(photo.bytes!)};
      await prefs.setString(key, jsonEncode(map));
    } catch (_) {
      throw const CacheException('Foto profil gagal disimpan');
    }
  }
}