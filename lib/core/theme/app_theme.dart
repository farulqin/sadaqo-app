import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:sadaqo/core/constants/app_colors.dart';
import 'package:sadaqo/core/theme/app_palette.dart';

/// Satu-satunya tempat untuk mengatur tampilan global aplikasi.
class AppTheme {
  AppTheme._();

  static ThemeData of(AppThemeMode mode) => _build(AppPalette.of(mode));

  static ThemeData get light => of(AppThemeMode.light);

  static ThemeData _build(AppPalette p) {
    final dark = p.mode == AppThemeMode.dark;
    final glass = p.isGlass;

    final scheme = dark
        ? ColorScheme.dark(
            primary: AppColors.limeGreen,
            onPrimary: AppColors.forestGreen,
            secondary: AppColors.limeGreen,
            onSecondary: AppColors.forestGreen,
            surface: p.surface,
            onSurface: p.textDark,
            error: p.error,
            surfaceTint: Colors.transparent,
          )
        : ColorScheme.light(
            primary: AppColors.forestGreen,
            onPrimary: Colors.white,
            secondary: AppColors.limeGreen,
            onSecondary: p.textDark,
            // Glass: permukaan dasar dibuat pekat agar menu/dialog tetap terbaca.
            surface: glass ? const Color(0xFFF1F6E8) : p.surface,
            onSurface: p.textDark,
            error: p.error,
            surfaceTint: glass ? Colors.transparent : AppColors.forestGreen,
          );

    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: p.background,
      colorScheme: scheme,
      // Riak sentuhan yang sama di semua platform.
      splashFactory: InkRipple.splashFactory,
      // Perpindahan halaman yang halus (zoom/fade) di semua platform.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.appBar,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: AppColors.forestGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              animationDuration: const Duration(milliseconds: 200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ).copyWith(
              // Bayangan membesar saat hover, mengecil saat ditekan.
              elevation: WidgetStateProperty.resolveWith<double?>((states) {
                if (states.contains(WidgetState.disabled)) return 0;
                if (states.contains(WidgetState.pressed)) return 0;
                if (states.contains(WidgetState.hovered)) return 6;
                return 2;
              }),
              shadowColor: WidgetStatePropertyAll(
                dark ? Colors.black.withValues(alpha: 0.5) : AppColors.forestGreen.withValues(alpha: 0.45),
              ),
            ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          animationDuration: const Duration(milliseconds: 200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.sandBeige),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.sandBeige),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.brandInk, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.popup,
        indicatorColor: AppColors.limeGreen,
      ),
    );

    // Tampilan Terang dibiarkan persis seperti sebelumnya.
    if (!dark && !glass) return base;

    // Tambahan untuk Gelap dan Liquid Glass.
    final extra = base.copyWith(
      canvasColor: p.popup,
      dividerTheme: DividerThemeData(color: p.sandBeige),
      dialogTheme: DialogThemeData(
        backgroundColor: p.popup,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.popup,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.popup,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.popup,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.brandInk),
      textSelectionTheme: TextSelectionThemeData(cursorColor: p.brandInk),
    );
    if (!dark) return extra;

    return extra.copyWith(
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color?>(
          (s) => s.contains(WidgetState.selected) ? AppColors.limeGreen : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (s) => s.contains(WidgetState.selected) ? AppColors.forestGreen : p.sandBeige,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
          (s) => s.contains(WidgetState.selected) ? AppColors.limeGreen : p.textMuted,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (s) => s.contains(WidgetState.selected) ? AppColors.limeGreen : null,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.forestGreen),
        side: BorderSide(color: p.textMuted, width: 1.5),
      ),
    );
  }
}
