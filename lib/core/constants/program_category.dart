import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_assets.dart';

/// Kategori program. Urutan enum = urutan tampil di beranda.
enum ProgramCategory {
  masjid(
    key: 'masjid',
    label: 'Masjid & Mushola',
    shortLabel: 'Masjid',
    icon: Icons.mosque, // cadangan jika gambar ikon tidak ditemukan
    iconAsset: AppAssets.iconMasjid,
    colorStart: Color(0xFF1F3D2B),
    colorEnd: Color(0xFF4E7D5B),
  ),
  sosial(
    key: 'sosial',
    label: 'Bantuan Sosial',
    shortLabel: 'Sosial',
    icon: Icons.volunteer_activism,
    iconAsset: AppAssets.iconSosial,
    colorStart: Color(0xFF2E5E3E),
    colorEnd: Color(0xFF7FB08A),
  ),
  zakat(
    key: 'zakat',
    label: 'Zakat',
    shortLabel: 'Zakat',
    icon: Icons.calculate,
    iconAsset: AppAssets.iconZakat,
    colorStart: Color(0xFF8A6D1F),
    colorEnd: Color(0xFFD9B84A),
  ),
  duafa(
    key: 'duafa',
    label: 'Kaum Duafa',
    shortLabel: 'Duafa',
    icon: Icons.groups,
    iconAsset: AppAssets.iconDuafa,
    colorStart: Color(0xFF3A6B47),
    colorEnd: Color(0xFFA3D65C),
  ),
  qurban(
    key: 'qurban',
    label: 'Qurban Bersama',
    shortLabel: 'Qurban',
    icon: Icons.pets,
    iconAsset: AppAssets.iconQurban,
    colorStart: Color(0xFF6B5B3A),
    colorEnd: Color(0xFFC9B98A),
  );

  const ProgramCategory({
    required this.key,
    required String label,
    required String shortLabel,
    required this.icon,
    required this.colorStart,
    required this.colorEnd,
    String? iconAsset,
  })  : _label = label,
        _shortLabel = shortLabel,
        _iconAsset = iconAsset;

  final String key;
  final String _label;
  final String _shortLabel;
  final String? _iconAsset;
  final IconData icon;
  final Color colorStart;
  final Color colorEnd;

  /// Nama, nama singkat, dan ikon bisa diubah admin (lihat [CategoryOverrides]).
  /// Jika tidak diubah, nilai bawaan di atas yang dipakai.
  String get label => CategoryOverrides.labels[key] ?? _label;
  String get shortLabel => CategoryOverrides.shortLabels[key] ?? _shortLabel;
  String? get iconAsset => CategoryOverrides.iconAssets[key] ?? _iconAsset;

  /// Nilai bawaan (sebelum diubah admin), dipakai tombol "Kembalikan".
  String get defaultLabel => _label;
  String get defaultShortLabel => _shortLabel;
  String? get defaultIconAsset => _iconAsset;

  static ProgramCategory fromKey(String key) {
    return ProgramCategory.values.firstWhere(
      (c) => c.key == key,
      orElse: () => ProgramCategory.masjid,
    );
  }
}

/// Perubahan tampilan kategori dari dashboard admin (disimpan di memori,
/// nanti diganti data dari server). Kunci = [ProgramCategory.key].
class CategoryOverrides {
  CategoryOverrides._();

  static final Map<String, String> labels = {};
  static final Map<String, String> shortLabels = {};
  static final Map<String, String> iconAssets = {};
}
