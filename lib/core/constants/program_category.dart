import 'package:flutter/material.dart';

/// Kategori program donasi. Dipakai bersama oleh fitur campaign dan donation.
enum ProgramCategory {
  masjid(
    key: 'masjid',
    label: 'Masjid & Musala',
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
  yatim(
    key: 'yatim',
    label: 'Anak Yatim',
    shortLabel: 'Yatim',
    icon: Icons.child_care,
    colorStart: Color(0xFF3A6B47),
    colorEnd: Color(0xFFA3D65C),
  ),
  kurban(
    key: 'kurban',
    label: 'Kurban Patungan',
    shortLabel: 'Kurban',
    icon: Icons.agriculture,
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
  });

  final String key;
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color colorStart;
  final Color colorEnd;

  static ProgramCategory fromKey(String key) {
    return ProgramCategory.values.firstWhere(
      (c) => c.key == key,
      orElse: () => ProgramCategory.masjid,
    );
  }
}
