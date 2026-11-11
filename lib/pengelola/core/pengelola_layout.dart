import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ukuran layar Dashboard Pengelola:
/// HP (< 700), tablet (700-1099, navigasi samping ringkas), laptop/web (>= 1100).
class PengelolaLayout {
  PengelolaLayout._();

  static const double tablet = 700;
  static const double desktop = 1100;

  /// Lebar isi maksimal di layar lebar.
  static const double contentMax = 1200;

  /// Lebar formulir (buat kampanye, kirim dokumentasi, edit profil, dll).
  static const double formMax = 760;
}

/// ListView yang isinya dibatasi lebar maksimal dan diletakkan di tengah,
/// tetapi area gulirnya tetap selebar layar.
class ContentListView extends StatelessWidget {
  const ContentListView({
    super.key,
    required this.children,
    this.maxWidth = PengelolaLayout.contentMax,
    this.padding = const EdgeInsets.all(16),
  });

  final List<Widget> children;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final side = math.max(0.0, (c.maxWidth - maxWidth) / 2);
        return ListView(
          padding: padding.copyWith(
            left: padding.left + side,
            right: padding.right + side,
          ),
          children: children,
        );
      },
    );
  }
}

/// Menyusun kartu menjadi 1, 2, atau 3 kolom sesuai lebar yang tersedia.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 340,
    this.spacing = 14,
    this.maxColumns = 3,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = ((c.maxWidth + spacing) / (minItemWidth + spacing))
            .floor()
            .clamp(1, maxColumns)
            .toInt();
        final itemWidth = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children) SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}