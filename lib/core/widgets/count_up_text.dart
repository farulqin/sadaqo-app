import 'package:flutter/material.dart';

/// Teks angka yang naik dari 0 ke [value]. Angka memakai lebar tetap (tabular)
/// agar tidak bergoyang saat berubah. Bila [value] berubah, angka bergerak
/// dari nilai saat ini ke nilai baru.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 1100),
    this.textAlign,
    this.maxLines,
  });

  final num value;

  /// Mengubah angka menjadi teks, contoh: `Formatter.rupiah`.
  final String Function(num value) format;
  final TextStyle? style;
  final Duration duration;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final base = style ?? DefaultTextStyle.of(context).style;
    final s = base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: reduce ? Duration.zero : duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        format(v.round()),
        style: s,
        textAlign: textAlign,
        maxLines: maxLines,
      ),
    );
  }
}