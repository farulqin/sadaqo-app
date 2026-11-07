import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_assets.dart';

/// Kategori program. Urutan enum = urutan tampil di beranda.
enum ProgramCategory {
  masjid(
    key: 'masjid',
    label: 'Masjid & Mushola',
    shortLabel: 'Masjid',
    icon: Icons.mosque,
    colorStart: Color(0xFF1F3D2B),
    colorEnd: Color(0xFF4E7D5B),
  ),
  sosial(
    key: 'sosial',
    label: 'Bantuan Sosial',
    shortLabel: 'Sosial',
    icon: Icons.volunteer_activism,
    colorStart: Color(0xFF2E5E3E),
    colorEnd: Color(0xFF7FB08A),
  ),
  zakat(
    key: 'zakat',
    label: 'Zakat',
    shortLabel: 'Zakat',
    icon: Icons.calculate,
    colorStart: Color(0xFF8A6D1F),
    colorEnd: Color(0xFFD9B84A),
  ),
  duafa(
    key: 'duafa',
    label: 'Kaum Duafa',
    shortLabel: 'Duafa',
    icon: Icons.groups,
    colorStart: Color(0xFF3A6B47),
    colorEnd: Color(0xFFA3D65C),
  ),
  qurban(
    key: 'qurban',
    label: 'Qurban Bersama',
    shortLabel: 'Qurban',
    icon: Icons.pets, // cadangan jika gambar ikon tidak ditemukan
    iconAsset: AppAssets.iconQurban, // ikon kepala sapi
    colorStart: Color(0xFF6B5B3A),
    colorEnd: Color(0xFFC9B98A),
  );

  const ProgramCategory({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.colorStart,
    required this.colorEnd,
    this.iconAsset,
  });

  final String key;
  final String label;
  final String shortLabel;
  final IconData icon;
  final String? iconAsset;
  final Color colorStart;
  final Color colorEnd;

  static ProgramCategory fromKey(String key) {
    return ProgramCategory.values.firstWhere(
      (c) => c.key == key,
      orElse: () => ProgramCategory.masjid,
    );
  }
}