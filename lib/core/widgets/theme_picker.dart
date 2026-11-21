import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/theme/app_palette.dart';
import 'package:sadaqo/core/theme/theme_controller.dart';

/// Tiga pilihan tampilan dengan pratinjau mini. Dipakai di halaman Pengaturan
/// dan di lembar pilihan dari Beranda.
class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final ctl = ThemeController.instance;
    return ListenableBuilder(
      listenable: ctl,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: Row(
          children: [
            for (final mode in AppThemeMode.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ThemeOption(
                    mode: mode,
                    selected: ctl.selected == mode,
                    onTap: () => ctl.select(mode),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

IconData themeIcon(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.light:
      return Icons.light_mode_rounded;
    case AppThemeMode.dark:
      return Icons.dark_mode_rounded;
    case AppThemeMode.glass:
      return Icons.blur_on_rounded;
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.mode, required this.selected, required this.onTap});

  final AppThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Tampilan ${mode.label}',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.brandInk : AppColors.sandBeige,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 0.78,
                  child: Stack(
                    children: [
                      Positioned.fill(child: _MiniPreview(mode: mode)),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: AnimatedScale(
                          scale: selected ? 1 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          child: const CircleAvatar(
                            radius: 9,
                            backgroundColor: AppColors.limeGreen,
                            child: Icon(Icons.check_rounded, size: 13, color: AppColors.onLime),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(themeIcon(mode), size: 14, color: selected ? AppColors.brandInk : AppColors.textMuted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          mode.label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                            color: selected ? AppColors.brandInk : AppColors.textDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ilustrasi kecil tiap tampilan. Warnanya tetap (tidak ikut tema aktif).
class _MiniPreview extends StatelessWidget {
  const _MiniPreview({required this.mode});

  final AppThemeMode mode;

  @override
  Widget build(BuildContext context) {
    final Color header = const Color(0xFF1F3D2B);
    late final Decoration bg;
    late final Color card;
    Border? cardBorder;
    switch (mode) {
      case AppThemeMode.light:
        bg = const BoxDecoration(color: Color(0xFFF8F4EA));
        card = Colors.white;
        cardBorder = Border.all(color: const Color(0xFFE8DCC4));
      case AppThemeMode.dark:
        bg = const BoxDecoration(color: Color(0xFF0D1913));
        card = const Color(0xFF16251C);
        cardBorder = Border.all(color: const Color(0xFF26392D));
      case AppThemeMode.glass:
        bg = const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC9E1BE), Color(0xFFF6F1E1), Color(0xFFDCEBCB)],
          ),
        );
        card = Colors.white.withValues(alpha: 0.72);
        cardBorder = Border.all(color: Colors.white.withValues(alpha: 0.95));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: DecoratedBox(
        decoration: bg,
        child: Stack(
          children: [
            if (mode == AppThemeMode.glass)
              Positioned(
                left: -14,
                top: -14,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF3E8E41).withValues(alpha: 0.30),
                  ),
                ),
              ),
            Column(
              children: [
                Container(height: 16, color: header.withValues(alpha: mode == AppThemeMode.glass ? 0.75 : 1)),
                const SizedBox(height: 7),
                for (var i = 0; i < 2; i++)
                  Container(
                    height: 20,
                    margin: const EdgeInsets.fromLTRB(7, 0, 7, 6),
                    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(6), border: cardBorder),
                  ),
                const Spacer(),
                Container(
                  height: 14,
                  margin: const EdgeInsets.fromLTRB(9, 0, 9, 6),
                  decoration: BoxDecoration(
                    color: mode == AppThemeMode.light ? Colors.white : card,
                    borderRadius: BorderRadius.circular(8),
                    border: cardBorder,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 16,
                      margin: const EdgeInsets.only(left: 3),
                      height: 8,
                      decoration: BoxDecoration(color: AppColors.limeGreen, borderRadius: BorderRadius.circular(5)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Membuka lembar pilihan tampilan (dipakai dari Beranda).
Future<void> showThemeSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tampilan aplikasi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const ThemePicker(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text(
              'Pilihan tersimpan dan dipakai saat aplikasi dibuka lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Tombol ikon kecil di bar atas Beranda untuk memilih tampilan.
class ThemeQuickButton extends StatelessWidget {
  const ThemeQuickButton({super.key, this.color = Colors.white});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final mode = ThemeController.instance.selected;
        return IconButton(
          tooltip: 'Ganti tampilan',
          onPressed: () => showThemeSheet(context),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            transitionBuilder: (child, anim) => RotationTransition(
              turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: Icon(themeIcon(mode), key: ValueKey(mode), color: color, size: 24),
          ),
        );
      },
    );
  }
}
