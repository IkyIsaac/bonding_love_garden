import 'package:flutter/material.dart';

/// Design tokens transcribed from docs/design/botanical_play/DESIGN.md.
/// "Botanical Play": Deep Green primary, Warm Pink accent, hyper-rounded
/// geometry, soft diffused shadows. Not venue branding — venue branding
/// (logo, name, brand_colors) is runtime config from `venue_settings`,
/// never hardcoded here. This file is the *app chrome* design system only.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF00361A);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF1A4D2E);
  static const onPrimaryContainer = Color(0xFF88BD95);

  static const secondary = Color(0xFFB80049); // Warm Pink accent
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFE2165F);
  static const onSecondaryContainer = Color(0xFFFFFBFF);

  static const tertiary = Color(0xFF002F54);
  static const onTertiary = Color(0xFFFFFFFF);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  static const surface = Color(0xFFF8FAF5);
  static const onSurface = Color(0xFF191C19);
  static const surfaceVariant = Color(0xFFE1E3DE);
  static const onSurfaceVariant = Color(0xFF414942);
  static const outline = Color(0xFF717971);

  // Supportive highlights (status/info, warnings/active sessions, attention)
  static const statusBlue = Color(0xFF004678);
  static const statusOrange = Color(0xFFE87A00);
  static const statusYellow = Color(0xFFF2B705);
}

class AppRadii {
  AppRadii._();

  static const base = 8.0; // small inputs, nested elements
  static const standard = 16.0; // buttons, standard cards
  static const large = 24.0; // main containers, modals
  static const full = 9999.0; // status chips, avatars
}

class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const base = 8.0;
  static const sm = 12.0;
  static const md = 24.0;
  static const lg = 48.0;
  static const xl = 80.0;
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.onPrimaryContainer,
    secondary: AppColors.secondary,
    onSecondary: AppColors.onSecondary,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.onSecondaryContainer,
    tertiary: AppColors.tertiary,
    onTertiary: AppColors.onTertiary,
    error: AppColors.error,
    onError: AppColors.onError,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.onErrorContainer,
    surface: AppColors.surface,
    onSurface: AppColors.onSurface,
    surfaceContainerHighest: AppColors.surfaceVariant,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.surface,
    // Montserrat (headlines) / Inter (body) per DESIGN.md — bundle the actual
    // font assets when building out the design system; falls back to the
    // platform default until then.
    fontFamily: 'Inter',
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.large),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.large),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.standard),
      ),
    ),
  );
}
