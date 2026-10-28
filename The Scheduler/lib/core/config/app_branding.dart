import 'package:flutter/material.dart';

/// Describes all visual knobs that a client can easily customize.
///
/// Color Palette Guide (Modern Sophisticated Blue):
/// - [primaryColor]: Rich navy blue for depth and professionalism (headers, nav)
/// - [accentColor]: Vibrant modern blue for gradients and highlights
/// - [ctaColor]: Warm coral/orange for call-to-action buttons (adds visual warmth)
/// - [backgroundColor]: Warm off-white (not clinical white) for surfaces
class AppBranding {
  const AppBranding({
    required this.productName,
    required this.tagline,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    this.ctaColor,
    this.logoAsset,
    this.fontFamily,
  });

  final String productName;
  final String tagline;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  /// Optional warm accent color for CTAs (coral/orange). Falls back to accentColor.
  final Color? ctaColor;
  final String? logoAsset;
  final String? fontFamily;

  /// Returns the CTA color, falling back to accent if not specified
  Color get effectiveCtaColor => ctaColor ?? accentColor;

  AppBranding copyWith({
    String? productName,
    String? tagline,
    Color? primaryColor,
    Color? accentColor,
    Color? backgroundColor,
    Color? ctaColor,
    String? logoAsset,
    String? fontFamily,
  }) {
    return AppBranding(
      productName: productName ?? this.productName,
      tagline: tagline ?? this.tagline,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      ctaColor: ctaColor ?? this.ctaColor,
      logoAsset: logoAsset ?? this.logoAsset,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}
