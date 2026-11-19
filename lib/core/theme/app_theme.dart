import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import '../constants/app_colors.dart';

/// Satu-satunya tempat untuk mengatur tampilan global aplikasi.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.forestGreen,
        onPrimary: Colors.white,
        secondary: AppColors.limeGreen,
        onSecondary: AppColors.textDark,
        surface: Colors.white,
        onSurface: AppColors.textDark,
        error: AppColors.error,
      ),
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
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
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
                AppColors.forestGreen.withValues(alpha: 0.45),
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
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.sandBeige),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.sandBeige),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.forestGreen, width: 2),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.limeGreen,
      ),
    );
  }
}
