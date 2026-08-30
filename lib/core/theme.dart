import 'package:flutter/material.dart';

class AppColors {
  static const ink        = Color(0xFF0E1116);
  static const surface    = Color(0xFF161B22);
  static const surfaceAlt = Color(0xFF1C232D);
  static const border     = Color(0xFF2A323D);

  static const textHigh   = Color(0xFFE8EAED);
  static const textMid    = Color(0xFF9AA4B2);
  static const textLow    = Color(0xFF6B7684);

  static const accepted   = Color(0xFF3FB68B);
  static const contested  = Color(0xFFE0A340);
  static const rejected   = Color(0xFFE05C5C);
  static const collecting = Color(0xFF5B7FE0);
}

ThemeData appTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.accepted,
    secondary: AppColors.collecting,
    surface: AppColors.surface,
    error: AppColors.rejected,
    onSurface: AppColors.textHigh,
    outline: AppColors.border,
    outlineVariant: AppColors.border,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.ink,
    fontFamily: 'SF Pro Text',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textHigh,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accepted.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 64,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, letterSpacing: 0.2),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.textHigh, fontSize: 20,
        fontWeight: FontWeight.w600, letterSpacing: -0.4, height: 1.25,
      ),
      titleMedium: TextStyle(
        color: AppColors.textHigh, fontSize: 17,
        fontWeight: FontWeight.w600, letterSpacing: -0.3, height: 1.35,
      ),
      titleSmall: TextStyle(
        color: AppColors.textHigh, fontSize: 14,
        fontWeight: FontWeight.w600, letterSpacing: -0.1,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textMid, fontSize: 14, height: 1.5,
      ),
      bodySmall: TextStyle(
        color: AppColors.textMid, fontSize: 13, height: 1.45,
      ),
      labelSmall: TextStyle(
        color: AppColors.textLow, fontSize: 11,
        fontWeight: FontWeight.w600, letterSpacing: 1.1,
      ),
    ),
    dividerColor: AppColors.border,
  );
}