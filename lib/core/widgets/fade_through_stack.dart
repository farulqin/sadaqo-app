import 'package:flutter/material.dart';

class FadeThroughStack extends StatefulWidget {
  const FadeThroughStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 320),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  State<FadeThroughStack> createState() => _FadeThroughStackState();
}

class _FadeThroughStackState extends State<FadeThroughStack> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  late int _from = widget.index;
  late int _to = widget.index;

  // 0 - 35%: halaman lama memudar. 35 - 100%: halaman baru muncul.
  late final Animation<double> _outOpacity = Tween<double>(begin: 1, end: 0).animate(
    CurvedAnimation(parent: _c, curve: const Interval(0, 0.35, curve: Curves.easeIn)),
  );
  late final Animation<double> _inOpacity = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.35, 1, curve: Curves.easeOut),
  );
  late final Animation<double> _inScale = Tween<double>(begin: 0.94, end: 1).animate(
    CurvedAnimation(parent: _c, curve: const Interval(0.35, 1, curve: Curves.easeOutCubic)),
  );

  @override
  void didUpdateWidget(FadeThroughStack old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _from = _to = widget.index;
      _c.value = 1;
    } else {
      _from = old.index;
      _to = widget.index;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final animating = _c.value < 1 && _from != _to;
        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < widget.children.length; i++) _page(i, animating),
          ],
        );
      },
    );
  }

  Widget _page(int i, bool animating) {
    final isTo = i == _to;
    final isFrom = animating && i == _from;
    final visible = isTo || isFrom;

    Animation<double> opacity = const AlwaysStoppedAnimation<double>(1);
    Animation<double> scale = const AlwaysStoppedAnimation<double>(1);
    if (isFrom) opacity = _outOpacity;
    if (isTo && animating) {
      opacity = _inOpacity;
      scale = _inScale;
    }

    // Struktur pembungkus dibuat tetap agar state halaman tidak ter-reset.
    return Offstage(
      key: ValueKey(i),
      offstage: !visible,
      child: TickerMode(
        enabled: visible,
        child: IgnorePointer(
          ignoring: isFrom,
          child: FadeTransition(
            opacity: opacity,
            child: ScaleTransition(scale: scale, child: widget.children[i]),
          ),
        ),
      ),
    );
  }
}