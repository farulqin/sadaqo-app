import 'package:flutter/material.dart';

/// Pembungkus kartu: terangkat dengan bayangan lebih besar saat kursor di
/// atasnya (web/desktop), dan menyusut sedikit saat ditekan.
/// Ketukan tetap ditangani oleh `InkWell` di dalam kartu.
class InteractiveCard extends StatefulWidget {
  const InteractiveCard({
    super.key,
    required this.child,
    this.radius = 16,
    this.lift = 4,
    this.pressedScale = 0.98,
  });

  final Widget child;

  /// Harus sama dengan radius sudut kartu di dalamnya (agar bayangan pas).
  final double radius;

  /// Jarak angkat (piksel) saat hover. Pakai 0 bila kartu berada di carousel
  /// yang memotong bayangan.
  final double lift;
  final double pressedScale;

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _hover = false;
  bool _down = false;
  Offset? _start;

  void _setDown(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final scale = _down ? widget.pressedScale : (_hover ? 1.01 : 1.0);
    final dy = (_hover && !_down) ? -widget.lift : 0.0;
    final transform = Matrix4.translationValues(0, dy, 0)
        .multiplied(Matrix4.diagonal3Values(scale, scale, 1));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) {
          _start = e.position;
          _setDown(true);
        },
        onPointerMove: (e) {
          final s = _start;
          if (s != null && (e.position - s).distance > 12) _setDown(false);
        },
        onPointerUp: (_) => _setDown(false),
        onPointerCancel: (_) => _setDown(false),
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: transform,
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hover ? 0.16 : 0.06),
                blurRadius: _hover ? 22 : 10,
                offset: Offset(0, _hover ? 10 : 4),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}