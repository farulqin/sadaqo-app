import 'package:flutter/material.dart';

/// Efek tekan untuk tombol: menyusut saat disentuh, lalu memantul kembali.
/// Memakai [Listener], jadi tidak mengganggu `onPressed` tombol di dalamnya.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.scale = 0.96,
    this.enabled = true,
  });

  final Widget child;

  /// Skala saat ditekan (1.0 = tanpa efek).
  final double scale;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;
  Offset? _start;

  void _setDown(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!widget.enabled || reduce) return widget.child;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _start = e.position;
        _setDown(true);
      },
      onPointerMove: (e) {
        // Jari menggeser (scroll): batalkan efek tekan.
        final s = _start;
        if (s != null && (e.position - s).distance > 12) _setDown(false);
      },
      onPointerUp: (_) => _setDown(false),
      onPointerCancel: (_) => _setDown(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: Duration(milliseconds: _down ? 90 : 260),
        curve: _down ? Curves.easeOut : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

extension PressableWidget on Widget {
  /// Contoh: `ElevatedButton(...).pressable()`
  Widget pressable({double scale = 0.96, bool enabled = true}) =>
      PressableScale(scale: scale, enabled: enabled, child: this);
}