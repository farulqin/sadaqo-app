import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:sadaqo/core/theme/app_theme.dart';
import 'package:sadaqo/core/theme/theme_controller.dart';

/// Membungkus MaterialApp. Saat tampilan berganti:
///  1. mengambil tangkapan layar tampilan lama,
///  2. memasang tema baru dan membangun ulang seluruh pohon widget
///     (warna di AppColors dibaca saat build, jadi semua widget harus dibangun ulang),
///  3. memudarkan tangkapan lama sehingga perpindahan terlihat halus.
class ThemeScope extends StatefulWidget {
  const ThemeScope({super.key, required this.builder});

  final Widget Function(BuildContext context, ThemeData theme) builder;

  @override
  State<ThemeScope> createState() => _ThemeScopeState();
}

class _ThemeScopeState extends State<ThemeScope> with SingleTickerProviderStateMixin {
  final _boundaryKey = GlobalKey();
  final _ctl = ThemeController.instance;
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  ui.Image? _snapshot;

  @override
  void initState() {
    super.initState();
    _ctl.addListener(_onChanged);
    _ctl.beforeChange = _capture;
  }

  @override
  void dispose() {
    _ctl.removeListener(_onChanged);
    _ctl.beforeChange = null;
    _snapshot?.dispose();
    _fade.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) return;
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ratio = View.of(context).devicePixelRatio.clamp(1.0, 2.0);
      final image = await boundary.toImage(pixelRatio: ratio);
      if (!mounted) {
        image.dispose();
        return;
      }
      _snapshot?.dispose();
      setState(() => _snapshot = image);
      _fade.value = 1;
      // Tunggu hingga tangkapan lama benar-benar tergambar sebelum tema diganti.
      await WidgetsBinding.instance.endOfFrame;
    } catch (_) {
      // Bila tangkapan gagal (mis. renderer tidak mendukung), ganti tema tanpa efek.
    }
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    // Paksa seluruh widget dibangun ulang agar membaca warna yang baru.
    (context as Element).visitChildren(_markAll);
    if (_snapshot != null) {
      _fade.animateBack(0, curve: Curves.easeOut).whenComplete(() {
        if (!mounted) return;
        setState(() {
          _snapshot?.dispose();
          _snapshot = null;
        });
      });
    }
  }

  static void _markAll(Element element) {
    element.markNeedsBuild();
    element.visitChildren(_markAll);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(_ctl.effective);
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            key: _boundaryKey,
            child: widget.builder(context, theme),
          ),
        ),
        if (_snapshot != null)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _fade,
                child: RawImage(image: _snapshot, fit: BoxFit.fill),
              ),
            ),
          ),
      ],
    );
  }
}
