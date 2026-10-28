import 'package:flutter/material.dart';

/// Core design tokens aligned to the React parity spec.
/// These are the single source of truth for spacing, radius, shadows, colors, and typography.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  /// Convenience padding tokens
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets pagePadding = EdgeInsets.all(lg);
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
}

class AppRadius {
  AppRadius._();

  static const double xs = 6.0;
  static const double sm = 8.0; // Buttons, inputs
  static const double md = 12.0; // Cards, dialogs
  static const double lg = 16.0; // Large containers/bottom sheets
  static const double full = 9999.0; // Pills/avatars

  // Component-specific aliases for clarity
  static const double button = sm;
  static const double input = sm;
  static const double card = md;
  static const double dialog = lg;
  static const double bottomSheet = lg;
  static const double chip = 20.0;
}

class AppShadows {
  AppShadows._();

  static const BoxShadow card = BoxShadow(
    color: Color(0x0D000000), // 5% black
    offset: Offset(0, 2),
    blurRadius: 8,
  );

  static const BoxShadow dropdown = BoxShadow(
    color: Color(0x1A000000), // 10% black
    offset: Offset(0, 4),
    blurRadius: 12,
  );

  static const BoxShadow modal = BoxShadow(
    color: Color(0x26000000), // 15% black
    offset: Offset(0, 8),
    blurRadius: 24,
  );
}

class AppElevation {
  AppElevation._();

  static const double none = 0.0;
  static const double xs = 1.0;
  static const double sm = 2.0;
  static const double md = 4.0;
  static const double lg = 8.0;
  static const double xl = 12.0;
}

class AppIconSize {
  AppIconSize._();

  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
}

class AppColors {
  AppColors._();

  // Core brand
  static const Color primary = Color(0xFF2563EB); // Brand blue
  static const Color primaryDark = Color(0xFF1E40AF);

  // Neutrals
  static const Color surface = Colors.white;
  static const Color surfaceSubtle = Color(0xFFFAFAFA); // Neutral-50
  static const Color border = Color(0xFFE5E7EB); // Neutral-200
  static const Color textPrimary = Color(0xFF111827); // Neutral-900
  static const Color textSecondary = Color(0xFF4B5563); // Neutral-600
  static const Color textDisabled = Color(0xFF9CA3AF); // Neutral-400

  // Semantic
  static const Color success = Color(0xFF16A34A); // Green-600
  static const Color warning = Color(0xFFF59E0B); // Orange-500
  static const Color error = Color(0xFFDC2626); // Red-600
  static const Color infoMuted = Color(0xFF2563EB); // Brand info

  // Risk/status tokens
  static const Color riskLow = Color(0xFF16A34A);
  static const Color riskLowBg = Color(0xFFE8F5E9);
  static const Color riskLowBorder = Color(0xFFC8E6C9);

  static const Color riskMedium = Color(0xFFF59E0B);
  static const Color riskMediumBg = Color(0xFFFFF4E5);
  static const Color riskMediumBorder = Color(0xFFFAD7A0);

  static const Color riskHigh = Color(0xFFDC2626);
  static const Color riskHighBg = Color(0xFFFDEDED);
  static const Color riskHighBorder = Color(0xFFF6C7C7);

  static const Color riskUnknown = Color(0xFF6B7280);
  static const Color riskUnknownBg = Color(0xFFF3F4F6);
  static const Color riskUnknownBorder = Color(0xFFE5E7EB);

  static const Color statusApproved = Color(0xFF16A34A);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusRejected = Color(0xFFDC2626);

  // Accents (retained for compatibility)
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color info = primary;
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle bodyLg = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle bodyMd = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle label = TextStyle(
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
}
