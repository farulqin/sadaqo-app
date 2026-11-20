import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/widgets/pressable_scale.dart';

class GlassNavItem {
  const GlassNavItem({required this.label, required this.iconBuilder});

  final String label;

  /// Membangun ikon dengan warna yang ditentukan bar (aktif atau tidak).
  final Widget Function(Color color) iconBuilder;
}

/// Bottom navbar melayang berbahan kaca (blur) dengan indikator "cair" yang
/// meluncur antar tab: memanjang saat bergerak cepat, lalu memantul di tujuan.
class GlassNavBar extends StatefulWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<GlassNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<GlassNavBar> createState() => _GlassNavBarState();
}

class _GlassNavBarState extends State<GlassNavBar> with SingleTickerProviderStateMixin {
  static const _spring = SpringDescription(mass: 1, stiffness: 210, damping: 20);
  static const double _barHeight = 70;
  static const double _hPad = 8;
  static const double _indicatorW = 62;
  static const double _indicatorH = 34;
  static const double _indicatorTop = 10;

  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
    value: widget.selectedIndex.toDouble(),
  );

  @override
  void didUpdateWidget(GlassNavBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) _moveTo(widget.selectedIndex);
  }

  void _moveTo(int i) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.value = i.toDouble();
      return;
    }
    _c.animateWith(SpringSimulation(_spring, _c.value, i.toDouble(), _c.velocity));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.navShadow,
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: _barHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.navTop,
                      AppColors.navBottom,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.navBorder, width: 1.2),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemW = (constraints.maxWidth - _hPad * 2) / n;
                    return AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) => Stack(
                        children: [
                          _indicator(itemW),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: _hPad),
                              child: Row(
                                children: [
                                  for (var i = 0; i < n; i++)
                                    SizedBox(
                                      width: itemW,
                                      child: _NavItemView(
                                        item: widget.items[i],
                                        // 1 = tepat di atas tab ini, 0 = jauh.
                                        t: (1 - (_c.value - i).abs()).clamp(0.0, 1.0),
                                        onTap: () => widget.onSelected(i),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _indicator(double itemW) {
    final stretch = (_c.velocity.abs() * 0.07).clamp(0.0, 0.6);
    final w = _indicatorW * (1 + stretch);
    final h = _indicatorH * (1 - stretch * 0.22);
    final cx = _hPad + itemW * (_c.value + 0.5);
    return Positioned(
      left: cx - w / 2,
      top: _indicatorTop + (_indicatorH - h) / 2,
      width: w,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.limeGreen.withValues(alpha: 0.95),
              AppColors.limeGreen.withValues(alpha: 0.75),
            ],
          ),
          borderRadius: BorderRadius.circular(h / 2),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.limeGreen.withValues(alpha: 0.45),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemView extends StatelessWidget {
  const _NavItemView({required this.item, required this.t, required this.onTap});

  final GlassNavItem item;
  final double t;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Ikon berada di atas indikator lime (teks gelap); label berada di bar.
    final iconColor = Color.lerp(AppColors.textDark, AppColors.onLime, t)!;
    final color = Color.lerp(AppColors.textDark, AppColors.brandInk, t)!;
    final active = t > 0.5;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: PressableScale(
          scale: 0.9,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Column(
              children: [
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: Center(
                    child: Transform.scale(
                      scale: 1 + 0.12 * t,
                      child: item.iconBuilder(iconColor),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}