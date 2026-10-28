import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_branding.dart';
import 'app_tokens.dart';

export 'app_tokens.dart';

/// Animation durations (kept here for compatibility)
class AppDuration {
  AppDuration._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
}

// ============================================================================
// THEME BUILDER
// ============================================================================

/// Builds theme from AppBranding configuration
ThemeData buildAppTheme(AppBranding branding, {Brightness? brightness}) {
  final isDark = brightness == Brightness.dark;
  return isDark ? _buildDarkTheme(branding) : _buildLightTheme(branding);
}

/// Builds light theme with modern sophisticated blue palette
ThemeData _buildLightTheme(AppBranding branding) {
  final textTheme = _buildTextTheme(branding, isDark: false);

  // Modern Sophisticated Blue Color Scheme
  // Rich navy primary + vibrant blue accent + warm coral CTAs
  // Warm neutrals (stone/cream) instead of cold clinical whites
  final colorScheme = ColorScheme.fromSeed(
    seedColor: branding.primaryColor,
    primary: branding.primaryColor,
    secondary: branding.accentColor,
    tertiary: branding.effectiveCtaColor, // Warm coral for CTAs
    // Warm surface spectrum (stone/cream tones, not cold grays)
    surface: const Color(0xFFFAFAF9), // Stone 50 - warm off-white
    surfaceContainerLowest: const Color(0xFFFFFFFF), // Pure white for cards
    surfaceContainerLow: const Color(0xFFFAFAF9), // Stone 50
    surfaceContainer: const Color(0xFFF5F5F4), // Stone 100
    surfaceContainerHigh: const Color(0xFFE7E5E4), // Stone 200
    surfaceContainerHighest: const Color(0xFFD6D3D1), // Stone 300
    // Rich contrast for readability
    onSurface: const Color(0xFF1C1917), // Stone 900 - warm black
    onSurfaceVariant: const Color(0xFF57534E), // Stone 600
    // Warm borders
    outline: const Color(0xFFD6D3D1), // Stone 300
    outlineVariant: const Color(0xFFE7E5E4), // Stone 200
    brightness: Brightness.light,
  );

  return _buildThemeData(
    branding: branding,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackground: branding.backgroundColor,
    isDark: false,
  );
}

/// Builds dark theme with sophisticated blue undertones
ThemeData _buildDarkTheme(AppBranding branding) {
  final textTheme = _buildTextTheme(branding, isDark: true);

  // Lighter primary for dark mode visibility
  final darkPrimary = _lightenColor(branding.primaryColor, 0.25);

  // Modern dark theme with warm undertones and blue accents
  final colorScheme = ColorScheme.fromSeed(
    seedColor: branding.primaryColor,
    primary: darkPrimary,
    secondary: branding.accentColor,
    tertiary: branding.effectiveCtaColor, // Warm coral for CTAs
    // Dark surfaces with subtle warmth (not cold gray)
    surface: const Color(0xFF1C1917), // Stone 900 - warm dark
    surfaceContainerLowest: const Color(0xFF0C0A09), // Stone 950
    surfaceContainerLow: const Color(0xFF1C1917), // Stone 900
    surfaceContainer: const Color(0xFF292524), // Stone 800
    surfaceContainerHigh: const Color(0xFF44403C), // Stone 700
    surfaceContainerHighest: const Color(0xFF57534E), // Stone 600
    // Warm light text for readability
    onSurface: const Color(0xFFFAFAF9), // Stone 50
    onSurfaceVariant: const Color(0xFFA8A29E), // Stone 400
    // Dark borders
    outline: const Color(0xFF57534E), // Stone 600
    outlineVariant: const Color(0xFF44403C), // Stone 700
    brightness: Brightness.dark,
  );

  return _buildThemeData(
    branding: branding,
    colorScheme: colorScheme,
    textTheme: textTheme,
    scaffoldBackground: const Color(0xFF020617), // Slate 950
    isDark: true,
  );
}

/// Build text theme with Inter font
TextTheme _buildTextTheme(AppBranding branding, {required bool isDark}) {
  final hasCustomFont =
      branding.fontFamily != null && branding.fontFamily!.trim().isNotEmpty;

  final baseTheme = isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;

  TextTheme textTheme;
  if (hasCustomFont) {
    textTheme = baseTheme.apply(fontFamily: branding.fontFamily);
  } else {
    textTheme = GoogleFonts.interTextTheme(baseTheme);
  }

  // Apply BOLDER font weights and clear hierarchy - Agent U0 (2025-11-28)
  return textTheme.copyWith(
    displayLarge: textTheme.displayLarge?.copyWith(
      fontWeight: FontWeight.w800, // Bolder
      letterSpacing: -1.5,
      height: 1.1,
    ),
    displayMedium: textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.w700, // Bolder
      letterSpacing: -0.5,
      height: 1.15,
    ),
    displaySmall: textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w700, // Bolder
      letterSpacing: 0,
      height: 1.2,
    ),
    headlineLarge: textTheme.headlineLarge?.copyWith(
      fontWeight: FontWeight.w700, // Bolder
      letterSpacing: -0.5,
      height: 1.2,
    ),
    headlineMedium: textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700, // Bolder
      letterSpacing: -0.25,
      height: 1.25,
    ),
    headlineSmall: textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700, // Bolder
      letterSpacing: 0,
      height: 1.3,
    ),
    titleLarge: textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700, // Bolder
      letterSpacing: 0,
      height: 1.3,
    ),
    titleMedium: textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600, // Increased from 500
      letterSpacing: 0.1,
      height: 1.35,
    ),
    titleSmall: textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600, // Increased from 500
      letterSpacing: 0.1,
      height: 1.35,
    ),
    bodyLarge: textTheme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      height: 1.5,
    ),
    bodyMedium: textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.5,
    ),
    bodySmall: textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.5,
    ),
    labelLarge: textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600, // Increased from 500
      letterSpacing: 0.1,
    ),
    labelMedium: textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600, // Increased from 500
      letterSpacing: 0.5,
    ),
    labelSmall: textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );
}

/// Main theme data builder
ThemeData _buildThemeData({
  required AppBranding branding,
  required ColorScheme colorScheme,
  required TextTheme textTheme,
  required Color scaffoldBackground,
  required bool isDark,
}) {
  final onPrimaryColor = _contrastColor(colorScheme.primary);

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scaffoldBackground,
    textTheme: textTheme,

    // ========================================================================
    // APP BAR
    // ========================================================================
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      backgroundColor: colorScheme.primary,
      foregroundColor: onPrimaryColor,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: onPrimaryColor,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: onPrimaryColor),
      actionsIconTheme: IconThemeData(color: onPrimaryColor),
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),

    // ========================================================================
    // NAVIGATION - Enhanced by Agent U0 (2025-11-28)
    // Stronger active indicator contrast and modern styling
    // ========================================================================
    navigationBarTheme: NavigationBarThemeData(
      height: 80,
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      // Stronger indicator with more opacity for better visibility
      indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          // Bolder primary color for selected icons
          return IconThemeData(
            color: colorScheme.primary,
            size: AppIconSize.md,
          );
        }
        return IconThemeData(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          size: AppIconSize.md,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700, // Bolder for selected
          );
        }
        return textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
        );
      }),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    navigationRailTheme: NavigationRailThemeData(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 24),
      unselectedIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),
      selectedLabelTextStyle: textTheme.labelLarge?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      useIndicator: true,
      minWidth: 72,
      minExtendedWidth: 200,
    ),

    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          );
        }
        return textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: colorScheme.primary);
        }
        return IconThemeData(color: colorScheme.onSurfaceVariant);
      }),
    ),

    drawerTheme: DrawerThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppRadius.lg),
          bottomRight: Radius.circular(AppRadius.lg),
        ),
      ),
    ),

    // ========================================================================
    // BUTTONS
    // ========================================================================
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: onPrimaryColor,
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        elevation: isDark ? 2 : 1,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        side: BorderSide(color: colorScheme.outline),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ).copyWith(
        side: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.12));
          }
          if (states.contains(WidgetState.pressed)) {
            return BorderSide(color: colorScheme.primary, width: 2);
          }
          return BorderSide(color: colorScheme.outline);
        }),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        minimumSize: const Size(64, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
        highlightColor: colorScheme.primary.withValues(alpha: 0.08),
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: onPrimaryColor,
      elevation: 4,
      focusElevation: 6,
      hoverElevation: 6,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      extendedTextStyle: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: onPrimaryColor,
      ),
    ),

    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return onPrimaryColor;
          }
          return colorScheme.onSurface;
        }),
        side: WidgetStateProperty.all(BorderSide(color: colorScheme.outline)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        )),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ),

    // ========================================================================
    // INPUTS
    // ========================================================================
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? colorScheme.surfaceContainerHigh
          : colorScheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(
          color: colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      labelStyle: textTheme.bodyLarge?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      floatingLabelStyle: textTheme.bodySmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: textTheme.bodySmall?.copyWith(
        color: colorScheme.error,
      ),
      helperStyle: textTheme.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      prefixIconColor: colorScheme.onSurfaceVariant,
      suffixIconColor: colorScheme.onSurfaceVariant,
    ),

    dropdownMenuTheme: DropdownMenuThemeData(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      menuStyle: MenuStyle(
        backgroundColor: WidgetStateProperty.all(colorScheme.surface),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(4),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        )),
      ),
    ),

    // ========================================================================
    // CARDS & CONTAINERS
    // ========================================================================
    cardTheme: CardThemeData(
      color: isDark ? colorScheme.surfaceContainerLow : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: isDark ? 4 : 2,
      // Softer, warmer shadows with subtle blue tint
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.4)
          : const Color(0xFF1A365D).withValues(alpha: 0.08), // Navy-tinted shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      margin: EdgeInsets.zero,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      titleTextStyle: textTheme.headlineSmall?.copyWith(
        color: colorScheme.onSurface,
      ),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheet),
        ),
      ),
      dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      dragHandleSize: const Size(32, 4),
      showDragHandle: true,
      modalElevation: 8,
    ),

    // ========================================================================
    // CHIPS
    // ========================================================================
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primary.withValues(alpha: 0.15),
      disabledColor: colorScheme.onSurface.withValues(alpha: 0.12),
      deleteIconColor: colorScheme.onSurfaceVariant,
      labelStyle: textTheme.labelLarge?.copyWith(
        color: colorScheme.onSurface,
      ),
      secondaryLabelStyle: textTheme.labelLarge?.copyWith(
        color: colorScheme.primary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      side: BorderSide(color: colorScheme.outline),
      showCheckmark: true,
      checkmarkColor: colorScheme.primary,
    ),

    // ========================================================================
    // LIST TILES
    // ========================================================================
    listTileTheme: ListTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
      titleTextStyle: textTheme.bodyLarge,
      subtitleTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      leadingAndTrailingTextStyle: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 24,
      minVerticalPadding: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      selectedTileColor: colorScheme.primary.withValues(alpha: 0.08),
      selectedColor: colorScheme.primary,
      dense: false,
      visualDensity: VisualDensity.standard,
    ),

    expansionTileTheme: ExpansionTileThemeData(
      iconColor: colorScheme.onSurfaceVariant,
      collapsedIconColor: colorScheme.onSurfaceVariant,
      textColor: colorScheme.onSurface,
      collapsedTextColor: colorScheme.onSurface,
      backgroundColor: colorScheme.surfaceContainerLow,
      collapsedBackgroundColor: Colors.transparent,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),

    // ========================================================================
    // TABS
    // ========================================================================
    tabBarTheme: TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: colorScheme.onSurfaceVariant,
      labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: textTheme.labelLarge,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: colorScheme.primary, width: 3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: colorScheme.outlineVariant,
      overlayColor: WidgetStateProperty.all(
        colorScheme.primary.withValues(alpha: 0.08),
      ),
      tabAlignment: TabAlignment.start,
    ),

    // ========================================================================
    // PROGRESS INDICATORS
    // ========================================================================
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.primary.withValues(alpha: 0.2),
      circularTrackColor: colorScheme.primary.withValues(alpha: 0.2),
      linearMinHeight: 4,
    ),

    // ========================================================================
    // SNACKBAR
    // ========================================================================
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark
          ? colorScheme.surfaceContainerHighest
          : const Color(0xFF323232),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: Colors.white,
      ),
      actionTextColor: colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      insetPadding: const EdgeInsets.all(16),
    ),

    // ========================================================================
    // TOOLTIPS & BADGES
    // ========================================================================
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : const Color(0xFF616161),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      textStyle: textTheme.bodySmall?.copyWith(
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      waitDuration: const Duration(milliseconds: 500),
      showDuration: const Duration(seconds: 2),
    ),

    badgeTheme: BadgeThemeData(
      backgroundColor: colorScheme.error,
      textColor: colorScheme.onError,
      textStyle: textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),

    // ========================================================================
    // SWITCHES & CHECKBOXES
    // ========================================================================
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.outline;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary.withValues(alpha: 0.5);
        }
        return colorScheme.surfaceContainerHighest;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.transparent;
        }
        return colorScheme.outline;
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(onPrimaryColor),
      side: BorderSide(color: colorScheme.outline, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return colorScheme.outline;
      }),
    ),

    // ========================================================================
    // SLIDERS
    // ========================================================================
    sliderTheme: SliderThemeData(
      activeTrackColor: colorScheme.primary,
      inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.24),
      thumbColor: colorScheme.primary,
      overlayColor: colorScheme.primary.withValues(alpha: 0.12),
      valueIndicatorColor: colorScheme.primary,
      valueIndicatorTextStyle: textTheme.labelMedium?.copyWith(
        color: onPrimaryColor,
      ),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
    ),

    // ========================================================================
    // DATE/TIME PICKERS
    // ========================================================================
    datePickerTheme: DatePickerThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: colorScheme.primary,
      headerForegroundColor: onPrimaryColor,
      dayStyle: textTheme.bodyMedium,
      weekdayStyle: textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      yearStyle: textTheme.bodyLarge,
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary;
        }
        return Colors.transparent;
      }),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return onPrimaryColor;
        }
        return colorScheme.onSurface;
      }),
      todayBackgroundColor: WidgetStateProperty.all(Colors.transparent),
      todayForegroundColor: WidgetStateProperty.all(colorScheme.primary),
      todayBorder: BorderSide(color: colorScheme.primary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      dayShape: WidgetStateProperty.all(const CircleBorder()),
    ),

    timePickerTheme: TimePickerThemeData(
      backgroundColor: colorScheme.surface,
      hourMinuteColor: colorScheme.surfaceContainerHigh,
      hourMinuteTextColor: colorScheme.onSurface,
      dialBackgroundColor: colorScheme.surfaceContainerHigh,
      dialHandColor: colorScheme.primary,
      dialTextColor: colorScheme.onSurface,
      entryModeIconColor: colorScheme.onSurfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      hourMinuteShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),

    // ========================================================================
    // MENUS & POPUPS
    // ========================================================================
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(colorScheme.surface),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(4),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        )),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    ),

    menuButtonTheme: MenuButtonThemeData(
      style: ButtonStyle(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      textStyle: textTheme.bodyMedium,
    ),

    // ========================================================================
    // DIVIDER
    // ========================================================================
    dividerTheme: DividerThemeData(
      color: colorScheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),

    // ========================================================================
    // DATA TABLES
    // ========================================================================
    dataTableTheme: DataTableThemeData(
      headingTextStyle: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      dataTextStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface,
      ),
      headingRowColor: WidgetStateProperty.all(
        colorScheme.surfaceContainerLow,
      ),
      dataRowColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return colorScheme.primary.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.hovered)) {
          return colorScheme.onSurface.withValues(alpha: 0.04);
        }
        return Colors.transparent;
      }),
      dividerThickness: 1,
      horizontalMargin: 16,
      columnSpacing: 24,
    ),

    // ========================================================================
    // MISC
    // ========================================================================
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    ),

    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(
        colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      trackColor: WidgetStateProperty.all(
        colorScheme.surfaceContainerLow,
      ),
      radius: const Radius.circular(AppRadius.full),
      thickness: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) return 8.0;
        return 6.0;
      }),
    ),

    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStateProperty.all(
        colorScheme.surfaceContainerLow,
      ),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        side: BorderSide(color: colorScheme.outline),
      )),
      textStyle: WidgetStateProperty.all(textTheme.bodyLarge),
      hintStyle: WidgetStateProperty.all(
        textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 16),
      ),
    ),

    searchViewTheme: SearchViewThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      dividerColor: colorScheme.outlineVariant,
      headerTextStyle: textTheme.titleLarge,
    ),
  );
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/// Returns a contrasting color (black or white) for the given color
Color _contrastColor(Color color) {
  final luminance = color.computeLuminance();
  return luminance > 0.5 ? Colors.black : Colors.white;
}

/// Lightens a color by the given amount (0.0 to 1.0)
Color _lightenColor(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightened = hsl.withLightness(
    (hsl.lightness + amount).clamp(0.0, 1.0),
  );
  return lightened.toColor();
}

// ============================================================================
// EXTENSION FOR EASY ACCESS
// ============================================================================

/// Extension to access design tokens from BuildContext
extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get textTheme => theme.textTheme;
}

// ============================================================================
// DESIGN SYSTEM USAGE GUIDE - Agent U0 (2025-11-28)
// ============================================================================
//
// ## SPACING
// Use AppSpacing constants instead of hardcoded values:
//   ✓ padding: EdgeInsets.all(AppSpacing.md)
//   ✓ SizedBox(height: AppSpacing.sm)
//   ✗ padding: EdgeInsets.all(16) // Don't hardcode
//
// Common patterns:
//   - Cards: AppSpacing.cardPadding
//   - Pages: AppSpacing.pagePadding
//   - Sections: AppSpacing.sectionPadding
//
// ## BORDER RADIUS
// Use AppRadius for consistent rounded corners (10-14px range):
//   ✓ borderRadius: BorderRadius.circular(AppRadius.card)
//   ✓ borderRadius: BorderRadius.circular(AppRadius.button)
//   ✗ borderRadius: BorderRadius.circular(8) // Don't hardcode
//
// ## COLORS
// Access via context.colorScheme:
//   ✓ color: context.colorScheme.primary
//   ✓ color: AppColors.success // For semantic colors
//   ✗ color: Color(0xFF2563EB) // Don't hardcode hex
//
// ## TYPOGRAPHY
// Use context.textTheme with bolder hierarchy:
//   - Headlines: titleLarge, headlineSmall (w700)
//   - Body: bodyLarge, bodyMedium (w400)
//   - Labels: labelLarge, labelMedium (w600)
//
// Example:
//   Text('Section Title', style: context.textTheme.titleLarge)
//
// ## ICONS
// Use AppIconSize constants:
//   ✓ Icon(Icons.add, size: AppIconSize.md)
//   ✗ Icon(Icons.add, size: 24) // Don't hardcode
//
// ## REUSABLE COMPONENTS
// Located in lib/core/ui/components/:
//   - AppCard: Consistent card styling
//   - AppButton: Standardized buttons
//   - AppChip: Filter chips
//   - SectionHeader: Section headers
//   - EmptyState, ErrorState: From lib/core/ui/state_widgets.dart
//
// ## RESPONSIVE
// Components should handle narrow widths without overflow.
// Use lib/core/ui/responsive_helpers.dart when needed.
//
// ============================================================================
