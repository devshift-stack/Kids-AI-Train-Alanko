import 'package:flutter/material.dart';
import 'package:kids_ai_shared/kids_ai_shared.dart';

/// Alanko App Theme
/// Verwendet das gemeinsame Design-System aus kids_ai_shared
///
/// Für app-spezifische Anpassungen können hier Overrides hinzugefügt werden.
/// Alle Basis-Werte kommen aus dem Shared Package.
class AppTheme {
  AppTheme._();

  // Re-export colors from shared
  static const Color primaryColor = KidsColors.primary;
  static const Color secondaryColor = KidsColors.secondary;
  static const Color accentColor = KidsColors.accent;
  static const Color backgroundColor = KidsColors.background;
  static const Color surfaceColor = KidsColors.surface;
  static const Color errorColor = KidsColors.error;
  static const Color successColor = KidsColors.success;
  static const Color warningColor = KidsColors.warning;

  // Age Group Colors
  static const Color preschoolColor = KidsColors.preschool;
  static const Color earlySchoolColor = KidsColors.earlySchool;
  static const Color lateSchoolColor = KidsColors.lateSchool;

  // Text Colors
  static const Color textPrimary = KidsColors.textPrimary;
  static const Color textSecondary = KidsColors.textSecondary;
  static const Color textLight = KidsColors.textLight;

  // Gradients
  static const LinearGradient primaryGradient = KidsGradients.primary;
  static const LinearGradient alanGradient = KidsGradients.character;

  // Border Radius
  static const double radiusSmall = KidsSpacing.radiusSm;
  static const double radiusMedium = KidsSpacing.radiusMd;
  static const double radiusLarge = KidsSpacing.radiusLg;
  static const double radiusXLarge = KidsSpacing.radiusXl;

  // Spacing
  static const double spacingXs = KidsSpacing.xs;
  static const double spacingSm = KidsSpacing.sm;
  static const double spacingMd = KidsSpacing.md;
  static const double spacingLg = KidsSpacing.lg;
  static const double spacingXl = KidsSpacing.xl;
  static const double spacingXxl = KidsSpacing.xxl;

  // Shadows
  static List<BoxShadow> get softShadow => KidsShadows.soft;
  static List<BoxShadow> get cardShadow => KidsShadows.card;

  // Theme Data - uses shared theme
  static ThemeData get lightTheme => KidsTheme.light;

  // Age-specific helpers
  static Color getAgeGroupColor(int age) => KidsColors.getAgeColor(age);

  static double getFontSizeForAge(int age, double baseSize) {
    if (age <= 5) return baseSize * 1.3;
    if (age <= 8) return baseSize * 1.15;
    return baseSize;
  }
}
