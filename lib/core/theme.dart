import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const Color navyBlue = Color(0xFF1E3A5F);
  static const Color ethiopianGreen = Color(0xFF2D7A4F);
  static const Color goldenYellow = Color(0xFFF4B942);

  // Secondary Colors
  static const Color lightBlue = Color(0xFF3D5A7F);
  static const Color tealGreen = Color(0xFF4A9F7A);
  static const Color warmGold = Color(0xFFFFC947);
  static const Color skyBlue = Color(0xFF5B8ABF);
  static const Color deepGreen = Color(0xFF1B5E4A);

  // Neutral Colors - Light Mode
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F9FA);
  static const Color lightGray = Color(0xFFE8EDF5);
  static const Color mediumGray = Color(0xFF94A3B8);
  static const Color darkGray = Color(0xFF475569);
  static const Color charcoal = Color(0xFF1E293B);

  // Neutral Colors - Dark Mode
  static const Color bgDark = Color(0xFF0F172A);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Functional / Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color pending = Color(0xFF8B5CF6);

  // Text Colors
  static const Color textPrimary = charcoal;
  static const Color textSecondary = mediumGray;
  static const Color textHint = Color(0xFFB0B8C4);

  // Background Colors
  static const Color scaffoldBackground = offWhite;
  static const Color cardBackground = white;
  static const Color scaffoldBackgroundDark = bgDark;
  static const Color cardBackgroundDark = cardDark;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFF2D7A4F),
      Color(0xFF1E3A5F),
      Color(0xFFF4B942),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.6, 1.0],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      Color(0xFF2D7A4F),
      Color(0xFF4A9F7A),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [
      Color(0xFF1E3A5F),
      Color(0xFF3D5A7F),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [
      Color(0xFFF4B942),
      Color(0xFFFFC947),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Shadow System
  static List<BoxShadow> getShadow(int elevation) {
    switch (elevation) {
      case 1:
        return [
          BoxShadow(
            color: navyBlue.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];
      case 2:
        return [
          BoxShadow(
            color: navyBlue.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ];
      case 4:
        return [
          BoxShadow(
            color: navyBlue.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ];
      case 8:
        return [
          BoxShadow(
            color: navyBlue.withOpacity(0.16),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ];
      default:
        return [];
    }
  }
}

class AppSpacing {
  AppSpacing._();

  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
}

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamilyPrimary = 'Inter';
  static const String fontFamilySecondary = 'Poppins';

  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.charcoal,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.charcoal,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.charcoal,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.charcoal,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.darkGray,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.mediumGray,
    fontFamily: fontFamilyPrimary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
    fontFamily: fontFamilySecondary,
  );
}

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.navyBlue,
    scaffoldBackgroundColor: AppColors.offWhite,
    colorScheme: const ColorScheme.light(
      primary: AppColors.ethiopianGreen,
      secondary: AppColors.goldenYellow,
      tertiary: AppColors.lightBlue,
      error: AppColors.error,
      surface: AppColors.white,
      onPrimary: AppColors.white,
      onSecondary: AppColors.navyBlue,
      onError: AppColors.white,
      onSurface: AppColors.charcoal,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navyBlue,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 2,
      shadowColor: AppColors.navyBlue.withOpacity(0.1),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ethiopianGreen,
        foregroundColor: AppColors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.goldenYellow,
      ),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.navyBlue,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.ethiopianGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.heading1,
      headlineMedium: AppTextStyles.heading2,
      titleLarge: AppTextStyles.heading3,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      labelSmall: AppTextStyles.caption,
    ),
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.navyBlue,
    scaffoldBackgroundColor: AppColors.bgDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.tealGreen,
      secondary: AppColors.warmGold,
      tertiary: AppColors.skyBlue,
      error: AppColors.error,
      surface: AppColors.cardDark,
      onPrimary: AppColors.navyBlue,
      onSecondary: AppColors.navyBlue,
      onError: AppColors.white,
      onSurface: AppColors.textPrimaryDark,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navyBlue,
      foregroundColor: AppColors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.tealGreen,
        foregroundColor: AppColors.navyBlue,
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.warmGold,
      ),
    ),
    iconTheme: const IconThemeData(
      color: AppColors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.lightBlue),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.tealGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    textTheme: const TextTheme(
      displayLarge: AppTextStyles.heading1,
      headlineMedium: AppTextStyles.heading2,
      titleLarge: AppTextStyles.heading3,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      labelSmall: AppTextStyles.caption,
    ).apply(
      bodyColor: AppColors.textPrimaryDark,
      displayColor: AppColors.textPrimaryDark,
    ),
  );
}
