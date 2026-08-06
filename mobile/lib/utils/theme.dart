import 'package:flutter/material.dart';

/// Central color tokens for HOM. All screens must reference these instead of
/// raw `Color(...)` / `Colors.*` literals so the palette can be themed
/// (e.g. dark mode) from a single place.
class AppColors {
  AppColors._();

  // ─── Brand ────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0E9F6E);
  static const Color primaryDark = Color(0xFF0B7A55);
  static const Color primaryLight = Color(0xFFE8F5F0);
  static const Color ink = Color(0xFF0E1A14);
  static const Color whatsapp = Color(0xFF25D366);

  // ─── Surfaces & text ──────────────────────────────────────────────────────
  static const Color background = Color(0xFFF6F7F5);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  // ─── Semantics ────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  // ─── Neutrals (Material grey scale) ───────────────────────────────────────
  static const Color white = Colors.white;
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color black = Colors.black;
  static const Color black87 = Color(0xDD000000);
  static const Color black54 = Color(0x8A000000);
  static const Color black38 = Color(0x61000000);
  static const Color black26 = Color(0x42000000);
  static const Color black12 = Color(0x1F000000);
  static const Color transparent = Colors.transparent;
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ─── Status palette (Material values) ─────────────────────────────────────
  static const Color red = Color(0xFFF44336);
  static const Color redAccent = Color(0xFFFF5252);
  static const Color red50 = Color(0xFFFFEBEE);
  static const Color red100 = Color(0xFFFFCDD2);
  static const Color red200 = Color(0xFFEF9A9A);
  static const Color red300 = Color(0xFFE57373);
  static const Color red400 = Color(0xFFEF5350);
  static const Color red500 = Color(0xFFF44336);
  static const Color red600 = Color(0xFFE53935);
  static const Color red700 = Color(0xFFD32F2F);
  static const Color red800 = Color(0xFFC62828);

  static const Color orange = Color(0xFFFF9800);
  static const Color orange50 = Color(0xFFFFF3E0);
  static const Color orange100 = Color(0xFFFFE0B2);
  static const Color orange700 = Color(0xFFF57C00);
  static const Color orange800 = Color(0xFFEF6C00);

  static const Color amber = Color(0xFFFFC107);
  static const Color amber50 = Color(0xFFFFF8E1);
  static const Color amber100 = Color(0xFFFFECB3);
  static const Color amber200 = Color(0xFFFFE082);
  static const Color amber400 = Color(0xFFFFCA28);
  static const Color amber500 = Color(0xFFFFC107);
  static const Color amber700 = Color(0xFFFFA000);
  static const Color amber900 = Color(0xFFFF6F00);

  static const Color green = Color(0xFF4CAF50);
  static const Color green50 = Color(0xFFE8F5E9);
  static const Color green100 = Color(0xFFC8E6C9);
  static const Color green700 = Color(0xFF388E3C);

  static const Color blue = Color(0xFF2196F3);
  static const Color blue50 = Color(0xFFE3F2FD);
  static const Color blue700 = Color(0xFF1976D2);

  // ─── Decorative palette ───────────────────────────────────────────────────
  static const Color indigo = Color(0xFF3F51B5);
  static const Color teal = Color(0xFF009688);
  static const Color teal50 = Color(0xFFE0F2F1);
  static const Color teal700 = Color(0xFF00796B);
  static const Color purple = Color(0xFF9C27B0);
  static const Color purple50 = Color(0xFFF3E5F5);
  static const Color purple700 = Color(0xFF7B1FA2);
  static const Color cyan500 = Color(0xFF00BCD4);
  static const Color cyan700 = Color(0xFF0097A7);
  static const Color deepOrange = Color(0xFFFF5722);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      elevation: 0.5,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 18,
        color: AppColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
    dividerTheme: DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
